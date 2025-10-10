package com.java.reactor.repository;
import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import org.springframework.stereotype.Repository;

import com.java.reactor.model.Product;

@Repository
public interface ProductRepository extends ReactiveMongoRepository<Product, Integer> {
}
