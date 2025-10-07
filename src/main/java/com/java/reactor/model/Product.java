package com.java.reactor.model;

import lombok.Data;

@Data
public class Product {

    private int id;
    private double title;
    private float price;
    private String description;
    private String category;
    private String image;
    private Rating rating;

}