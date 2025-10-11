package com.java.reactor.models;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreditCard extends CardInfo {

    private boolean emiAvailable;
    private int creditLimit;

}
