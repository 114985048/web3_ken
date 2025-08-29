// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";
import {TokenBank} from "../src/TokenBank.sol";

contract Deploy is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address recipient = vm.envOr("RECIPIENT", address(0));
        uint256 amount = vm.envOr("AMOUNT", uint256(0)); // 以代币最小单位（如 18 位）

        vm.startBroadcast(pk);

        MyToken token = new MyToken();
        TokenBank bank = new TokenBank(address(token));

        if (recipient != address(0) && amount > 0) {
            // 给测试地址转一笔 MTK 以便前端直接可用
            token.transfer(recipient, amount);
        }

        vm.stopBroadcast();

        console2.log("ChainId:", block.chainid);
        console2.log("Deployer:", vm.addr(pk));
        console2.log("MyToken:", address(token));
        console2.log("TokenBank:", address(bank));
        if (recipient != address(0) && amount > 0) {
            console2.log("Funded:", recipient, amount);
        }
    }
}


