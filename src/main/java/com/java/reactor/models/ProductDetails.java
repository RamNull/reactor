package com.java.reactor.models;


import java.util.List;


import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ProductDetails extends Product {

    public ProductDetails(Product product)
    {
        this.setProductId(product.getProductId());
        this.setAdditionalInfo(product.getAdditionalInfo());
        this.setBrand(product.getBrand());
        this.setMedia(product.getMedia());
        this.setSku(product.getSku());
        this.setCreatedAt(product.getCreatedAt());
        this.setName(product.getName());
        this.setCategory(product.getCategory());
        this.setSubCategory(product.getSubCategory());
        this.setTags(product.getTags());
        this.setSpecifications(product.getSpecifications());
    }

    private List<OfferCalculations> bestOffers;
    private List<OfferCalculations> userCardOffers;
}
