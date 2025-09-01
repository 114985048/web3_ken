package org.example.transfers;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import lombok.Data;
import java.math.BigInteger;
import java.time.LocalDateTime;

@Entity
@Data
public class Transfers {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String fromAddress;
    private String toAddress;
    private BigInteger amount;
    private String txHash;
    private Long blockNumber;
    private LocalDateTime timestamp;
}