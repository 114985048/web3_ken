// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {UpgradableNFTV2} from "../src/UpgradableNFTV2.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract UpgradeV2 is Script {
    // 现有的代理合约地址
    address constant PROXY_ADDRESS = 0xE24Fd5C15232E0CF461765d70f63d10652047F42;

    function run() external {
        // 获取部署者的私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);

        // 部署新的 UpgradableNFTV2 实现合约
        UpgradableNFTV2 newImplementation = new UpgradableNFTV2();
        console.log("New implementation deployed at:", address(newImplementation));

        // 获取代理合约的 UUPS 接口
        UUPSUpgradeable proxy = UUPSUpgradeable(PROXY_ADDRESS);

        // 执行升级并调用 upgradeV2 函数
        bytes memory upgradeData = abi.encodeWithSignature("upgradeV2()");
        proxy.upgradeToAndCall(address(newImplementation), upgradeData);

        // 验证升级后的 EIP-712 版本
        UpgradableNFTV2 proxyContract = UpgradableNFTV2(PROXY_ADDRESS);
        //string memory version = proxyContract.version();
        //console.log("EIP-712 Version after upgrade:", version);

        // 停止广播
        vm.stopBroadcast();

        console.log("Proxy upgraded to V2 at:", PROXY_ADDRESS);
    }
}
