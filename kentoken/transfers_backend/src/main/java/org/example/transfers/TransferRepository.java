package org.example.transfers;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface TransferRepository extends JpaRepository<Transfers, Long> {
    @Query("SELECT t FROM Transfers t WHERE LOWER(t.fromAddress) = LOWER(?1) OR LOWER(t.toAddress) = LOWER(?1)")
    List<Transfers> findByAddress(String address);
}