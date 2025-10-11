package com.java.reactor.postgres.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.java.reactor.postgres.entity.Offer;

public interface OfferRepository extends JpaRepository<Offer,String> {

    List<Offer> findByOfferIdIn(List<String> offerIds);
}
