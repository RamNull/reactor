package com.java.reactor.postgres.entity;

import com.java.reactor.postgres.enums.CardType;
import com.java.reactor.postgres.enums.CashbackType;
import com.java.reactor.postgres.enums.ProviderType;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Table(name = "offers")
@Data
public class Offer {

    @Id
    @Column(name = "offer_id")
    private String offerId;

    @Column(name = "offer_details")
    private String offerDetails;

    @Enumerated(EnumType.STRING)
    @Column(name="card_type")
    private CardType cardType;

    @Column(name= "bank_name")
    private String bankName;

    @Enumerated(EnumType.STRING)
    @Column(name= "provider_type")
    private ProviderType providerType;

    @Column(name= "emi_available")
    private boolean emi;

    @Column(name = "cashback_value")
    private Double  cashBack;

    @Enumerated(EnumType.STRING)
    @Column(name = "cashback_type")
    private CashbackType cashbackType;

    @Column(name= "cashback_max")
    private Double  maxCashBack;

}


     