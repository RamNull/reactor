---
layout: default
title: Reactor Example
description: A Comprehensive example on how to use Reactor
permalink: /example
---

# Reactor
Reactive programming is a programming paradigm that does async, non blocking I/O and event driven execution and Reactor is the library that handles reactive programming which makes the thread life easier. We have discussed in depth about the reactive programming and reactor in [https://ramnull.github.io/reactor](https://ramnull.github.io/reactor). In this page we will try to use the reactive programming to its max potential and to achieve we will be using different services and components like sql , no-sql , cache , web-flux along with blocking, non-blocking , parallel and single schedular types along with back-pressure cases  

# Scenario 
Lets assume a simple scenario of view cart or wishlist and should be able to share the cart details to others. seems simple right but this is not as simple as it looks as a lot of services and infra that works in the background. Just at higher level to get the information the aggregator service needs to make calls to multiple services like and follow multiple steps 

## Steps : 
1. pass Cart Details to Cart Service and fetch the products added in the cart this will just have the product Id and the count of each product you have ordered 
2. get the payment Details from payment Service which contains the different types payment methods and card details stored 
3. With the product Id you received you can try and fetch the product meta data from cache 
4. if data regarding the product doesn't exist in cache fetch the data from cache service 
5. update the cache so it can be reused when calls are made 
6. make a call to the stock and offer Service to check and fetch if there is stock available and if there are existing offers (offers service just gives the offerId. this decision is take to simulate sql call from the aggregator service)
7. if there is a stock available then get the offers applicable from the DB 
8. run a cup intensive business logic that runs applies the offers and gives you the top 3 offers that are applicable with both your existing payment methods and overall 
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


## Code



### Controller Implementation

```java
@RestController
public class ReviewController {
    private final WebClient webClient = WebClient.create();
    private final HandleProducts handleProducts;
    private final ProductRepository productRepository;
    private static final String uri = "https://fakestoreapi.com/products";

    public ReviewController(ProductRepository productRepository, HandleProducts handleProducts) {
        this.productRepository = productRepository;
        this.handleProducts = handleProducts;
    }

    @GetMapping("ap1/v1/products")
    public Flux<Product> getProducts(){
      return webClient.get().uri("https://fakestoreapi.com/products")
      .retrieve().bodyToFlux(Product.class);
    }

    @GetMapping("ap1/v1/productsSave")
    public Flux<Product> getProductAndSaveToDB(){
        int cores = Runtime.getRuntime().availableProcessors();
        System.out.println("CPU cores: " + cores);
        Flux<Product> productFlux = webClient.get().uri(uri).retrieve().bodyToFlux(Product.class)
        .parallel()
        .runOn(Schedulers.parallel())
        .transform(handleProducts::handle)
        .sequential()
        .collectList()
        .flatMapMany(productRepository::saveAll);
        return productFlux.limitRate(10).filter(x->x.getId()!=1);
    }
}
```

### Business Logic Handler

```java
@Service
public class HandleProducts {
    public ParallelFlux<Product> handle(ParallelFlux<Product> products) {
       return products.map(x->{
            if(x.getId()%2==0) {
                x.setPrice((float)(x.getPrice()*16.2));
                try {
                    Thread.sleep(1000);
                    System.out.println("thread Slept for 1 sec"+ Thread.currentThread().getName());
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }
            return x;
       });
    }
}
```

### Repository

```java
@Repository
public interface ProductRepository extends ReactiveMongoRepository<Product, Integer> {
}
```

### Model

```java
@Data
public class Product {
    private int id;
    private String title;
    private float price;
    private String description;
    private String category;
    private String image;
    private Rating rating;
}
```

## How It Works

1. **Fetch Products**: The `getProducts()` method uses WebClient to fetch product data from an external API
2. **Process in Parallel**: The `getProductAndSaveToDB()` method demonstrates:
   - Parallel processing using `.parallel()` and `.runOn(Schedulers.parallel())`
   - Custom transformation logic via `handleProducts::handle`
   - Backpressure control with `.limitRate(10)`
   - Filtering unwanted data
3. **Persist to Database**: Uses reactive MongoDB repository to save products asynchronously
4. **Thread Management**: Leverages Reactor's scheduler system for efficient CPU utilization

## Key Features Demonstrated

- **Reactive WebClient**: Non-blocking HTTP calls
- **Parallel Processing**: Utilizing multiple CPU cores
- **Backpressure**: Controlling the rate of data flow
- **Reactive Repository**: Non-blocking database operations
- **Thread Scheduling**: Efficient thread pool management

This example showcases the power of reactive programming for handling I/O-bound operations efficiently.
