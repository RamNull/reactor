package com.java.reactor.models;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CardInfo {

    private String number;
    private String name;
    private String validTill;
    private String cvv;
    private String bankName;
    private String provider;
}
