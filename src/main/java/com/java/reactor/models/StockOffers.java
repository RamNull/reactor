package com.java.reactor.models;

import java.util.List;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class StockOffers {

    private String productId;
    private List<String> offerIds;
    private int stock;
    private int price;

}
