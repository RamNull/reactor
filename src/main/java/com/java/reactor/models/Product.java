package com.java.reactor.models;

import java.time.LocalDateTime;
import java.util.Map;

import com.fasterxml.jackson.annotation.JsonFormat;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class Product {

    private String productId;
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createdAt;
    private String name;
    private String brand;
    private String sku;
    private String category;
    private String subCategory;
    private String[] tags;
    private Media media;
    private Map<String,?> specifications;
    private Map<String, ?> additionalInfo;
}
