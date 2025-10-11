package com.java.reactor.models;

import java.util.List;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CartDetails {

    private String userId;
    private List<ProductDetails> productDetails;
    
}
