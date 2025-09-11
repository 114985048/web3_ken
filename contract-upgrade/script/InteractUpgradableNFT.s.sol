// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {UpgradableNFT} from "../src/UpgradableNFT.sol";

contract InteractUpgradableNFT is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // 代理合约地址（你要交互的地址）
        UpgradableNFT nft = UpgradableNFT(0xE24Fd5C15232E0CF461765d70f63d10652047F42);

        // 1. 调用 mintWithURI
        uint256 tokenId = nft.mintWithURI(
            0xD02Df345F3DbbeFCE420048eC0f2562a18d40B0F, // 接收者地址
            "9527"                                      // tokenURI
        );
        console.log("Minted tokenId:", tokenId);

        // 2. 查询 tokenURI(1)
        string memory uri = nft.tokenURI(1);
        console.log("TokenURI(1):", uri);

        vm.stopBroadcast();
    }
}
