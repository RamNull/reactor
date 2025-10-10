package com.java.reactor.businesslogic;

import org.springframework.stereotype.Service;

import com.java.reactor.model.Product;

import reactor.core.publisher.ParallelFlux;


@Service
public class HandleProducts {

    public ParallelFlux<Product> handle(ParallelFlux<Product> products)
    {
       return products.map(x->{
            if(x.getId()%2==0) {
                x.setPrice((float)(x.getPrice()*16.2));
                try {
					Thread.sleep(1000);
                    System.out.println("thread Slept for 1 sec"+ Thread.currentThread().getName());
				} catch (InterruptedException e) {
                    // Restore interrupted status
                    Thread.currentThread().interrupt();
				}
        }
        return x;
       });
    }

    
}
