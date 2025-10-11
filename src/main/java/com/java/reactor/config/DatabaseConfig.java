package com.java.reactor.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.data.mongodb.repository.config.EnableReactiveMongoRepositories;

@Configuration
@EnableReactiveMongoRepositories(
    basePackages = "com.java.reactor.mongo"
)
@EnableJpaRepositories(
    basePackages = "com.java.reactor.postgres"
)
public class DatabaseConfig {

}
