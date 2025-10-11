package com.java.reactor.mongo.repository;
import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import org.springframework.stereotype.Repository;

import com.java.reactor.models.CartDetails;

@Repository
public interface CartDetailRepository extends ReactiveMongoRepository<CartDetails, String> {
}
