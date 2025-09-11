// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/UpgradableNFTV2.sol";

contract DeployUpgradableNFTV2 is Script {
    function run() external {
        // 从环境变量读取私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);

        // 部署逻辑合约
        UpgradableNFTV2 impl = new UpgradableNFTV2();
        console.log("UpgradableNFTV2 Implementation deployed at:", address(impl));

        // 你可以在这里部署一个 UUPS Proxy（ERC1967Proxy）
        // 如果你已经有 V1 Proxy，可以跳过 Proxy 部署
        // 示例：new ERC1967Proxy(address(impl), "");

        vm.stopBroadcast();
    }
}
