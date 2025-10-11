package com.java.reactor.models;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class PaymentInfo {
    private CardInfo[] debitCards;
    private CreditCard[] creditCards;

}
