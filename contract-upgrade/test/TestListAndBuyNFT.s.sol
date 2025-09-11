
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {UpgradableNFTV2} from "../src/UpgradableNFTV2.sol";

contract TestListAndBuyNFT is Script, Test {
    address constant PROXY_ADDRESS = 0xE24Fd5C15232E0CF461765d70f63d10652047F42;
    string constant NAME = "UpgradableNFT";
    string constant VERSION = "2";
    uint256 constant CHAIN_ID = 11155111; // Sepolia
    address constant VERIFYING_CONTRACT = PROXY_ADDRESS;

    function run() external {
        // 获取私钥
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        uint256 sellerPrivateKey = vm.envUint("SELLER_PRIVATE_KEY");
        uint256 buyerPrivateKey = vm.envUint("BUYER_PRIVATE_KEY");

        address deployer = vm.addr(deployerPrivateKey);
        address seller = vm.addr(sellerPrivateKey);
        address buyer = vm.addr(buyerPrivateKey);

        // 初始化合约
        UpgradableNFTV2 nft = UpgradableNFTV2(PROXY_ADDRESS);

        // 检查代理的实现地址
        bytes32 implSlot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        address implementation = address(uint160(uint256(vm.load(PROXY_ADDRESS, implSlot))));
        console.log("Current implementation:", implementation);
        assertEq(implementation, 0xDb209eEc3A3bE00F61aB9d4e320cB8Bc91791E3c, "Implementation address mismatch");

        // 检查 EIP-712 版本
        // try nft.version() returns (string memory version) {
        //     console.log("EIP-712 Version:", version);
        //     assertEq(version, VERSION, "EIP-712 version should be 2");
        // } catch Error(string memory reason) {
        //     console.log("Failed to get EIP-712 version:", reason);
        //     fail("EIP-712 version check failed");
        // }

        // 铸造 NFT
        uint256 tokenId;
        vm.startBroadcast(deployerPrivateKey);
        try nft.mintWithURI(seller, "https://example.com/nft/1") returns (uint256 id) {
            tokenId = id;
            console.log("Minted NFT with tokenId:", tokenId, "to seller:", seller);
        } catch Error(string memory reason) {
            console.log("Mint failed:", reason);
            fail("NFT minting failed");
        }
        vm.stopBroadcast();

        // 验证 NFT 所有权
        address owner = nft.ownerOf(tokenId);
        assertEq(owner, seller, "Seller should own the NFT");

        // 生成 EIP-712 签名
        uint256 price = 0.1 ether;
        uint256 nonce;
        try nft.getUserNonce(seller) returns (uint256 currentNonce) {
            nonce = currentNonce + 1;
            console.log("Using nonce:", nonce);
        } catch Error(string memory reason) {
            console.log("Failed to get nonce:", reason);
            fail("Nonce retrieval failed");
        }

        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(NAME)),
                keccak256(bytes(VERSION)),
                CHAIN_ID,
                VERIFYING_CONTRACT
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Listing(uint256 tokenId,uint256 price,uint256 nonce)"),
                tokenId,
                price,
                nonce
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sellerPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, bytes1(v));

        // 卖家挂单
        vm.startBroadcast(sellerPrivateKey);
        try nft.listNFTWithSignature(tokenId, price, nonce, signature) {
            //console.log("NFT listed with tokenId:", tokenId, "price:", price, "nonce:", nonce);
        } catch Error(string memory reason) {
            console.log("Listing failed:", reason);
            fail("NFT listing failed");
        }
        vm.stopBroadcast();

        // 验证挂单
        (bool isListed, uint256 listedPrice, address listedSeller, uint256 listedNonce) = nft.getListingInfo(tokenId);
        assertTrue(isListed, "NFT should be listed");
        assertEq(listedPrice, price, "Listing price should match");
        assertEq(listedSeller, seller, "Listing seller should match");
        assertEq(listedNonce, nonce, "Listing nonce should match");

        // 买家购买
        vm.startBroadcast(buyerPrivateKey);
        try nft.buyNFT{value: price}(tokenId) {
            console.log("NFT bought by buyer:", buyer, "for tokenId:", tokenId);
        } catch Error(string memory reason) {
            console.log("Buy failed:", reason);
            fail("NFT purchase failed");
        }
        vm.stopBroadcast();

        // 验证购买
        address newOwner = nft.ownerOf(tokenId);
        assertEq(newOwner, buyer, "NFT ownership should transfer to buyer");
        console.log("NFT ownership verified. New owner:", newOwner);

        (isListed, listedPrice, listedSeller, listedNonce) = nft.getListingInfo(tokenId);
        assertFalse(isListed, "Listing should be removed after purchase");
        console.log("Listing removed verified.");
    }
}