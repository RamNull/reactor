package com.java.reactor.models;

import org.springframework.boot.autoconfigure.amqp.RabbitConnectionDetails.Address;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class Payment {

    private String userId;
    private Address address;
    private PaymentInfo paymentInfo;

}
