---
layout: default
title: Reactor Example
description: A Comprehensive example on how to use Reactor
permalink: /example
---

# Reactor
Reactive programming is a programming paradigm that does async, non blocking I/O and event driven execution and Reactor is the library that handles reactive programming which makes the thread life easier. We have discussed in depth about the reactive programming and reactor in [Reactive programming](https://ramnull.github.io/reactor). In this page we will try to use the reactive programming to its max potential and to achieve we will be using different services and components like sql , no-sql , cache , web-flux along with blocking, non-blocking , parallel and single schedular types along with back-pressure cases  

# Scenario 
Lets assume a simple scenario of view cart or wishlist and should be able to share the cart details to others. seems simple right but this is not as simple as it looks as a lot of services and infra that works in the background. Just at higher level to get the information the aggregator service needs to make calls to multiple services like and follow multiple steps 

## Steps : 
1. pass Cart Details to Cart Service and fetch the products added in the cart this will just have the product Id and the count of each product you have ordered 
2. get the payment Details from payment Service which contains the different types payment methods and card details stored 
3. Get the product details from product Service
4. make a call to the stock and offer Service to check and fetch if there is stock available and if there are existing offers (offers service just gives the offerId. this decision is take to simulate sql call from the aggregator service)
7. if there is a stock available then get the offers applicable from the DB 
8. run a cpu intensive business logic that runs applies the offers and gives you the top 3 offers that are applicable with both your existing payment methods and overall 
9. save the final data to a NO sql DB so it can be shared with others 

## Services and Components : 

- ### Services :
    - Cart : To fetch the Cart information
    - Payments : To fetch the saved payments Methods 
    - Product : To fetch the product metadata
    - Stocks & Offers : to fetch the stock availability and applicable offers 
- ### Components : 
    - Redis : To cache the product information
    - mongo : To save the final cart details so it can be shared with others {we can even use cache to do this as this will be a short lived object but just to use mongo we are saving it in mongo}
    - Postgres : To get the offer Details from DB 

# Prerequisites  
in order to Replicate and use Services and Components we will be using mockApis and Scripts to add use [mock-api](https://mockapi.io/) or apps like [Mockoon](https://mockoon.com/download/) to create mocks for cart and other services. **prefer Mockoon as there are no restrictions on the number of mocks that you can make**.  

below are the data that you could download and use for mock 

- Product : [Download products mock data](./working-example/json/products.json)
- Payments : [Download payments mock data](./working-example/json/payments.json)
- Stocks & Offers : [Download stocks & offers mock data ](./working-example/json/stocks-offers.json)
- Cart : [Download Cart mock Data](./working-example/json/cart.json)
- Offers Scripts : [Download offers DB Script](./working-example/scripts/offers.sql)
- Postman-Collections: [Download postman collection](./working-example/postman/Reactor%20Mocks.postman_collection.json)

## Code


### Controller Implementation

Cart Controller will have a single Get api Call that fetches the Cart Details

```java
package com.java.reactor.controller;

import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import com.java.reactor.models.CartDetails;
import com.java.reactor.service.CartService;

import reactor.core.publisher.Mono;
import org.springframework.web.bind.annotation.GetMapping;


@RestController
public class CartController {

    private final CartService cartService;

    public CartController(CartService cartService)
    {
        this.cartService = cartService;
    }

    @GetMapping("/api/v1/cartDetails/{userId}")    
    public Mono<CartDetails> fetchCartDetails(@PathVariable String userId)
    {
        return cartService.getCartDetails(userId);
    }

}
```

### Service Implementation

The complete Flow happens in the Service. Here it executes the logic depending on the needs when needed it runs the code in non-blocking I/O threads other times it runs the process in parallel scheduler and when needed it runs in the process even runs in a single thread 

```java
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

// for running the CPU intensive works we use Scheduler parallel
private Mono<CartDetails> buildCartDetails(String userId, Flux<Product> products,
            Flux<Offer> offers,Flux<StockOffers> stockOffers, Mono<Payment> payment) {
        return Mono.zip(products.collectList(), offers.collectList(),stockOffers.collectList(),payment)
        .publishOn(Schedulers.parallel()) // anything downstream will run on `Schedulers.parallel()` thread poll 
                .map(x -> {
                    CartDetails cart = new CartDetails();
                    cart.setUserId(userId);
                    cart.setProductDetails(
                        buildProductDetails(x.getT1(),x.getT2(),x.getT3(),x.getT4()) // CPU intensive work
                    );
                    return cart;
                }
        );

    }

```

## How It Works

1. **Fetching Details in parallel** : `getCartDetailsByUserId(userId)` and `getPaymentDetails(userId)` gets the details in parallel and they run with web-flux so they are non-blocking 
2. **Selection of Cold and Hot Publishers**: In general reactive we use cold Publisher but when the same stream is need to be used by 2 different subscribers then it would be bad if we run the stream twice. in this scenario we can switch from cold to hot publisher but need to be careful on what type of hot publisher needs to be used 
    - `autoConnect()` : runs when at-least one subscriber subscribed to the stream 
    - `connect()` : runs irrespective if there are any subscribers or not 
    - `share()` : it internally runs `.refCount(1)` where it waits for 1 subscriber to start the streaming 
    - `refCount(n)` : it waits till there are n number of subscribers 
    - `cache()` : runs when there is at-least 1 subscriber but caches the data so it can be replayed this takes memory space 
3. **Bound Elastic** : Any non reactive I/O bound (I/O Blocking) execution can be switched from Event loops threads to bound elastic threads by using `subscribeOn(Schedulers.boundedElastic())` so the event loops can be used for reactive execution in the above code the JPA Hibernate is blocking I/O in such scenario we switch the execution from event loop to bound elastic thread pool FYI subscribe on is applied from the base in here its `Mono.fromCallable()`
4. **Parallel** : Any CPU intensive executions like building the final product details where it need to do a lot of streaming and processing will be moved to parallel thread pool which supports cpu intensive executions so we switch to parallel using `.publishOn(Schedulers.parallel())`  FYI publishOn is applied from the point its given to the downstream in the above example `Mono.Zip()` get all the details together and make sure that the next operation waits for the completion of all the flux and mono executions in it and after that we are switching to parallel thread pool its thread equivalent is `join()`
5. **Auto Switch to Reactive Stream** : when a reactive all is made after subscribeOn or publishOn the thread will be automatically switched to event loop thread like when `cartDetailRepository.saveAll(cartDetails);` call is made which runs mongo reactive repository it will switch back to reactive streams instead of running on the previous parallel thread pool
6. **BackPressure** : `Flux<List<String>> offerIds = stockOffers.flatMapIterable(StockOffers::getOfferIds).distinct().buffer(500);` we are trying to fetch only max 500 at a time after the processing is completed it takes the next 500 there are lot of other variations for back pressure please refer to [Reactive programming](https://ramnull.github.io/reactor). 


## Key Features Demonstrated

- **Reactive WebClient**: Non-blocking HTTP calls
- **Parallel Processing**: Utilizing multiple CPU cores
- **Backpressure**: Controlling the rate of data flow
- **Thread Scheduling**: Efficient thread pool management
- **Bound-Elastic** : When to use Bound elastic 

--- 

**FYI in reactive all ways pass the final statement as return or else there is a chance that the operation might not execute in the below code we are returning the original mono after saving it but it is ignored as it is not included in the final pipeline**

```java
        // the business logic will be run with schedular parallel
        Mono<CartDetails> cartDetails =  buildCartDetails(userId, products, offers,stockOffers, payment);
        // save the output to a reactive mongo DB 
        cartDetails.flatMap(cartDetailRepository::save);
        return cartDetails; // ❌ Returning original Mono, save operation is ignored
```

This example showcases the power of reactive programming for handling I/O-bound operations efficiently.