package com.java.reactor.service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import com.java.reactor.models.CardInfo;
import com.java.reactor.models.Cart;
import com.java.reactor.models.CartDetails;
import com.java.reactor.models.CartedProduct;
import com.java.reactor.models.OfferCalculations;
import com.java.reactor.models.Payment;
import com.java.reactor.models.PaymentInfo;
import com.java.reactor.models.Product;
import com.java.reactor.models.ProductDetails;
import com.java.reactor.models.StockOffers;
import com.java.reactor.mongo.repository.CartDetailRepository;
import com.java.reactor.postgres.entity.Offer;
import com.java.reactor.postgres.enums.CashbackType;
import com.java.reactor.postgres.repository.OfferRepository;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

@Service
public class CartService {

    private static final String PRODUCT_BASE_URL = "http://localhost:3000/api/v1/product/";
    private static final String CART_BASE_URL = "http://localhost:3003/api/v1/cart/";
    private static final String PAYMENT_BASE_URL = "http://localhost:3001/api/v1/payments/";
    private static final String STOCKS_BASE_URL = "http://localhost:3002/api/v1/details/";
    private final WebClient webClient = WebClient.create();
    private final OfferRepository offerRepository;
    private final CartDetailRepository cartDetailRepository;

    public CartService(OfferRepository offerRepository,CartDetailRepository cartDetailRepository) {
        this.offerRepository = offerRepository;
        this.cartDetailRepository = cartDetailRepository;
        
    }

    public Mono<CartDetails> getCartDetails(String userId) {

        // Both payment and cart details will be fetched in parallel as they are independent of each other
        Mono<Cart> cart = getCartDetailsByUserId(userId);
        Mono<Payment> payment = getPaymentDetails(userId);
        // product Id's will be used by other web-flux calls like getProductById and getStockAndOfferDetails and if made as cold publisher 2 different product Id  calls will be made so make them as hot publishers share starts when there is at-least 1 subscriber but since the subscribe is done at the end the will start at same time so it should be fine if there is any sequential operations that need to be handled then cache instead of share so it will replay the data non blocking 
        Flux<String> productIds = cart.flatMapIterable(Cart::getProducts).map(CartedProduct::getProductId).share();
        // Both products and stock and offer Details will n be fetched in parallel as they  don't depend on each other
        Flux<Product> products = productIds.flatMap(this::getProductById);
        Flux<StockOffers> stockOffers = productIds.flatMap(this::getStockAndOfferDetails).cache();
        // the stockOffers will be cached and replayed how-many times you want but since  we are caching it takes space
        // All the offerIds can collected and used once to get in bulk but too many in a  single call might not good so we keep buffer stream with 500 at a time
        Flux<List<String>> offerIds = stockOffers.flatMapIterable(StockOffers::getOfferIds).distinct().buffer(500);

        // the call to DB needs to be made bound elastic as jpa is non-reactive or else it will blocks the event loops when run in reactive pipeline
        Flux<Offer> offers = offerIds.flatMap(
                x -> Mono.fromCallable(
                        () -> offerRepository.findAllById(x)).subscribeOn(Schedulers.boundedElastic()) // bound elastic for non  reactive  blocking calls
                        .flatMapMany(Flux::fromIterable));

        // the business logic will be run with schedular parallel
        Mono<CartDetails> cartDetails =  buildCartDetails(userId, products, offers,stockOffers, payment);
        // save the output to a reactive mongo DB and return the value
        return cartDetails.flatMap(cartDetailRepository::save);
         
    }

    private Mono<Product> getProductById(String productId) {
        return webClient.get().uri(PRODUCT_BASE_URL + "{productId}", productId).retrieve().bodyToMono(Product.class);
    }

    private Mono<Cart> getCartDetailsByUserId(String userId) {
        return webClient.get().uri(CART_BASE_URL + "{userId}", userId).retrieve().bodyToMono(Cart.class);
    }

    private Mono<Payment> getPaymentDetails(String userId) {
        return webClient.get().uri(PAYMENT_BASE_URL + "{userId}", userId).retrieve().bodyToMono(Payment.class);
    }

    private Mono<StockOffers> getStockAndOfferDetails(String productId) {
        return webClient.get().uri(STOCKS_BASE_URL + "{productId}", productId).retrieve().bodyToMono(StockOffers.class);
    }

    private Mono<CartDetails> buildCartDetails(String userId, Flux<Product> products,
            Flux<Offer> offers,Flux<StockOffers> stockOffers, Mono<Payment> payment) {
        return Mono.zip(products.collectList(), offers.collectList(),stockOffers.collectList(),payment).publishOn(Schedulers.parallel())
                .map(x -> {
                    CartDetails cart = new CartDetails();
                    cart.setUserId(userId);
                    cart.setProductDetails(buildProductDetails(x.getT1(),x.getT2(),x.getT3(),x.getT4()));
                    return cart;
                }
        );

    }

    private List<ProductDetails> buildProductDetails(List<Product> products,List<Offer> offers,List<StockOffers> stockOffers,Payment payment)
    {
        List<ProductDetails> productDetails = new ArrayList<>();
        for (Product product : products) {
            ProductDetails productDetail = new ProductDetails(product);
            // Collect offer IDs for the current product
            Set<String> offerIds = stockOffers.stream().filter(x -> x.getProductId().equals(product.getProductId())).flatMap(x -> x.getOfferIds().stream()).collect(Collectors.toSet());
            double price = stockOffers.stream().filter(x -> x.getProductId().equals(product.getProductId())).map(x->x.getPrice()).findFirst().orElse(0);
            // Convert List to Map to get better performance 
            Map<String,Offer> offerMap = offers.stream().collect(Collectors.toMap(Offer::getOfferId, Function.identity()));
            List<Offer> productOffers = offerIds.stream().map(offerMap::get).filter(Objects::nonNull).toList();
            // calculate offers 
            List<OfferCalculations> finalOffers = productOffers.stream().map(x->{
                OfferCalculations offerCalculation = new OfferCalculations();
                offerCalculation.setOfferId(x.getOfferId());
                updateOfferDetails(offerCalculation, x,price);
                return offerCalculation;
            }).toList();

            productDetail.setBestOffers(finalOffers);
            // Get payment Info 
            PaymentInfo paymentInfo = payment.getPaymentInfo();
            List<OfferCalculations> curatedOffers = getCuratedOffers(finalOffers, paymentInfo,productOffers);
            productDetail.setUserCardOffers(curatedOffers);
            productDetails.add(productDetail);
        }

        return productDetails;

    }

    private void updateOfferDetails(OfferCalculations offerCalculations,Offer offer,double price)
    {
        if(offer.getCashbackType()==CashbackType.FLAT)
        {
            if(price>offer.getCashBack())
                offerCalculations.setFinalOfferPrice(price-offer.getCashBack());
            else
                offerCalculations.setOfferText("offer is not Applicable as the discount is greater than price");
        }
        else{
            double cashBackAmount = Math.max((price * offer.getCashBack()/100), offer.getMaxCashBack());
             offerCalculations.setFinalOfferPrice(price-cashBackAmount);
        }
    }

    private List<OfferCalculations> getCuratedOffers(List<OfferCalculations> finalOffers, PaymentInfo paymentInfo, List<Offer> productOffers) {
        List<OfferCalculations> offerCalculations = new ArrayList<>();
        addCardOffers(finalOffers, offerCalculations, paymentInfo.getDebitCards(), productOffers);
        addCardOffers(finalOffers, offerCalculations, paymentInfo.getCreditCards(), productOffers);
        return offerCalculations;
    }

    private <T extends CardInfo> void addCardOffers(List<OfferCalculations> finalOffers, List<OfferCalculations> offerCalculations, T[] cards, List<Offer> productOffers) {
        if (cards != null && cards.length != 0) {
            for (T cardInfo : cards) {
                String offerId = productOffers.stream()
                        .filter(x ->
                                Objects.equals(x.getBankName(), cardInfo.getBankName()) &&
                                Objects.equals(String.valueOf(x.getProviderType()), String.valueOf(cardInfo.getProvider()))
                        )
                        .map(Offer::getOfferId)
                        .findFirst()
                        .orElse(null);
                OfferCalculations offerCalc = finalOffers.stream().filter(x -> x.getOfferId().equals(offerId)).findFirst().orElse(null);
                if (offerCalc != null)
                    offerCalculations.add(offerCalc);
            }
        }
    }
}
