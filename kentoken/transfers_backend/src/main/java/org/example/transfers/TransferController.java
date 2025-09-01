package org.example.transfers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/transfers")
@CrossOrigin(origins = {
        "http://localhost:3000",
        "http://192.168.190.153:3000/"
})
public class TransferController {
    @Autowired
    private TransferRepository repository;

    @GetMapping("/{address}")
    public List<Transfers> getTransfersByAddress(@PathVariable String address) {
        return repository.findByAddress(address);
    }
}