// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {esRNT} from "../src/esRNT.sol";

contract DeployEsRNT is Script {
    function run() external {
        // Start broadcasting transactions using the private key
        vm.startBroadcast();

        // Deploy the esRNT contract
        esRNT contractInstance = new esRNT();

        // Stop broadcasting
        vm.stopBroadcast();

        // Log the deployed contract address
        //console.log("esRNT deployed to:", address(contractInstance));
    }
}