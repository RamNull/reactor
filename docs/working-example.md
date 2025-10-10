---
layout: default
title: Working Example
permalink: /example
---

# Working Example

This page demonstrates a complete working example of the Reactor framework in action.

## Product API Example

This example shows how to use Reactor to fetch, transform, and persist data from an external API.

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
