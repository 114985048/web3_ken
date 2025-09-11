// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {UpgradableNFT} from "../src/UpgradableNFT.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployUpgradableNFT is Script {
    function run() external {
        // 从环境变量读取私钥 (在 .env 设置 PRIVATE_KEY)
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署逻辑合约 (Implementation)
        UpgradableNFT implementation = new UpgradableNFT();

        // 2. 构造初始化参数 (对应 initialize)
        bytes memory data = abi.encodeWithSelector(
            UpgradableNFT.initialize.selector,
            "MyNFT",      // name
            "MNFT",       // symbol
            "https://example.com/metadata/", // baseURI
            vm.addr(deployerPrivateKey)      // owner
        );

        // 3. 部署 Proxy，并调用 initialize
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), data);

        // 4. 获取代理合约实例
        UpgradableNFT nft = UpgradableNFT(address(proxy));

        vm.stopBroadcast();

        console.log("Implementation deployed at:", address(implementation));
        console.log("Proxy deployed at:", address(proxy));
        console.log("UpgradableNFT (proxy) initialized with owner:", nft.owner());
    }
}
