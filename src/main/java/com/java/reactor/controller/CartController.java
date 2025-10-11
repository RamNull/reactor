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
