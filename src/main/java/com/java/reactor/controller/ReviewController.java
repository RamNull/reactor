package com.java.reactor.controller;

import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.reactive.function.client.WebClient;

import com.java.reactor.businesslogic.HandleProducts;
import com.java.reactor.model.Product;
import com.java.reactor.repository.ProductRepository;

import reactor.core.publisher.Flux;
import reactor.core.scheduler.Schedulers;


import org.springframework.web.bind.annotation.GetMapping;


@RestController
public class
 ReviewController {


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
        .transform(handleProducts::handle) // gives takes flux and gives out flux
        .sequential()
        .collectList()
        .flatMapMany(productRepository::saveAll); // flatmap takes mono<List<?>> and converts to flux 
        return productFlux.limitRate(10).filter(x->x.getId()!=1);
    }

}
