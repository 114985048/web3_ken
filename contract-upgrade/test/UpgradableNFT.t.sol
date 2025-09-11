// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/UpgradableNFT.sol";
import "../src/UpgradableNFTV2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title UpgradableNFT Test Contract
/// @notice Test V1 and V2 functionality of upgradable ERC721 contract and upgrade process
contract UpgradableNFTTest is Test {
    using ECDSA for bytes32;

    // Contract instances
    UpgradableNFT public v1Implementation;
    UpgradableNFTV2 public v2Implementation;
    ERC1967Proxy public proxy;
    UpgradableNFT public v1Proxy;
    UpgradableNFTV2 public v2Proxy;

    // Test accounts
    address public owner = address(0x1);
    address public user1 = 0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF; // address from private key 0x2
    address public user2 = 0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69; // address from private key 0x3
    address public buyer = address(0x4);

    // Test constants
    string constant NFT_NAME = "UpgradableNFT";
    string constant NFT_SYMBOL = "UNFT";
    string constant BASE_URI = "https://api.example.com/metadata/";
    string constant TOKEN_URI = "token1.json";

    // Event declarations
    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price, uint256 nonce);
    event NFTUnlisted(uint256 indexed tokenId, address indexed seller);
    event NFTBought(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);

    function setUp() public {
        // Set test account balances
        vm.deal(owner, 100 ether);
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(buyer, 100 ether);

        // Deploy V1 implementation contract
        v1Implementation = new UpgradableNFT();
        
        // Deploy proxy contract
        bytes memory initData = abi.encodeWithSelector(
            UpgradableNFT.initialize.selector,
            NFT_NAME,
            NFT_SYMBOL,
            BASE_URI,
            owner
        );
        proxy = new ERC1967Proxy(address(v1Implementation), initData);
        
        // Create proxy interface
        v1Proxy = UpgradableNFT(address(proxy));
        
        // Deploy V2 implementation contract
        v2Implementation = new UpgradableNFTV2();
    }

    /// @notice Test V1 basic functionality
    function testV1BasicFunctionality() public {
        console.log("=== Testing V1 Basic Functionality ===");
        
        // Switch to owner account
        vm.startPrank(owner);
        
        // Test initial state
        assertEq(v1Proxy.name(), NFT_NAME);
        assertEq(v1Proxy.symbol(), NFT_SYMBOL);
        assertEq(v1Proxy.baseURI(), BASE_URI);
        assertEq(v1Proxy.owner(), owner);
        
        console.log("Initial state verification passed");
        
        // Test minting functionality
        uint256 tokenId = v1Proxy.mintWithURI(user1, TOKEN_URI);
        assertEq(tokenId, 1);
        assertEq(v1Proxy.ownerOf(tokenId), user1);
        assertEq(v1Proxy.tokenURI(tokenId), string(abi.encodePacked(BASE_URI, TOKEN_URI)));
        
        console.log("Minting functionality test passed, TokenId:", tokenId);
        
        // Test setting base URI
        string memory newBaseURI = "https://newapi.example.com/metadata/";
        v1Proxy.setBaseURI(newBaseURI);
        assertEq(v1Proxy.baseURI(), newBaseURI);
        
        console.log("Set base URI functionality test passed");
        
        vm.stopPrank();
    }

    /// @notice Test V2 offline signature listing functionality
    function testV2SignatureListing() public {
        console.log("=== Testing V2 Offline Signature Listing ===");
        
        // First upgrade to V2
        _upgradeToV2();
        
        // Switch to owner to mint NFT
        vm.startPrank(owner);
        uint256 tokenId = v2Proxy.mintWithURI(user1, TOKEN_URI);
        vm.stopPrank();
        
        // Switch to user1 for signature listing
        vm.startPrank(user1);
        
        // Generate signature data
        uint256 price = 1 ether;
        uint256 nonce = 1;
        
        // Create signature using EIP712
        bytes32 structHash = keccak256(abi.encode(
            keccak256("Listing(uint256 tokenId,uint256 price,uint256 nonce)"),
            tokenId,
            price,
            nonce
        ));
        
        bytes32 domainSeparator = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("UpgradableNFT")),
            keccak256(bytes("2")),
            block.chainid,
            address(v2Proxy)
        ));
        
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user1PrivateKey(), hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        // Expect event
        vm.expectEmit(true, true, false, true);
        emit NFTListed(tokenId, user1, price, nonce);
        
        // Execute signature listing
        v2Proxy.listNFTWithSignature(tokenId, price, nonce, signature);
        
        // Verify listing state
        UpgradableNFTV2.ListingInfo memory listingInfo = v2Proxy.getListingInfo(tokenId);
        assertTrue(listingInfo.isListed);
        assertEq(listingInfo.price, price);
        assertEq(listingInfo.seller, user1);
        assertEq(listingInfo.nonce, nonce);
        assertEq(v2Proxy.getUserNonce(user1), nonce);
        
        console.log("Signature listing functionality test passed");
        
        vm.stopPrank();
    }

    /// @notice Test V2 buy NFT functionality
    function testV2BuyNFT() public {
        console.log("=== Testing V2 Buy NFT Functionality ===");
        
        // First upgrade to V2 and list NFT
        _upgradeToV2();
        _listNFT();
        
        // Switch to buyer to purchase NFT
        vm.startPrank(buyer);
        
        uint256 tokenId = 1;
        uint256 price = 1 ether;
        
        // Expect event
        vm.expectEmit(true, true, true, true);
        emit NFTBought(tokenId, user1, buyer, price);
        
        // Execute purchase
        v2Proxy.buyNFT{value: price}(tokenId);
        
        // Verify purchase result
        assertEq(v2Proxy.ownerOf(tokenId), buyer);
        UpgradableNFTV2.ListingInfo memory listingInfo = v2Proxy.getListingInfo(tokenId);
        assertFalse(listingInfo.isListed);
        
        console.log("Buy NFT functionality test passed");
        
        vm.stopPrank();
    }

    /// @notice Test contract upgrade process
    function testContractUpgrade() public {
        console.log("=== Testing Contract Upgrade Process ===");
        
        // Perform some operations in V1 state
        vm.startPrank(owner);
        uint256 tokenId1 = v1Proxy.mintWithURI(user1, "token1.json");
        uint256 tokenId2 = v1Proxy.mintWithURI(user2, "token2.json");
        
        // Record pre-upgrade state
        string memory oldBaseURI = v1Proxy.baseURI();
        address oldOwner = v1Proxy.owner();
        uint256 oldBalance1 = user1.balance;
        uint256 oldBalance2 = user2.balance;
        
        console.log("Pre-upgrade state:");
        console.log("- TokenId 1 owner:", v1Proxy.ownerOf(tokenId1));
        console.log("- TokenId 2 owner:", v1Proxy.ownerOf(tokenId2));
        console.log("- Base URI:", oldBaseURI);
        console.log("- Contract owner:", oldOwner);
        
        vm.stopPrank();
        
        // Execute upgrade
        vm.startPrank(owner);
        v1Proxy.upgradeToAndCall(address(v2Implementation), "");
        v2Proxy = UpgradableNFTV2(address(proxy));
        v2Proxy.upgradeV2();
        vm.stopPrank();
        
        // Verify post-upgrade state consistency
        assertEq(v2Proxy.name(), NFT_NAME);
        assertEq(v2Proxy.symbol(), NFT_SYMBOL);
        assertEq(v2Proxy.baseURI(), oldBaseURI);
        assertEq(v2Proxy.owner(), oldOwner);
        assertEq(v2Proxy.ownerOf(tokenId1), user1);
        assertEq(v2Proxy.ownerOf(tokenId2), user2);
        assertEq(v2Proxy.tokenURI(tokenId1), string(abi.encodePacked(oldBaseURI, "token1.json")));
        assertEq(v2Proxy.tokenURI(tokenId2), string(abi.encodePacked(oldBaseURI, "token2.json")));
        assertEq(user1.balance, oldBalance1);
        assertEq(user2.balance, oldBalance2);
        
        console.log("Post-upgrade state verification:");
        console.log("- TokenId 1 owner:", v2Proxy.ownerOf(tokenId1));
        console.log("- TokenId 2 owner:", v2Proxy.ownerOf(tokenId2));
        console.log("- Base URI:", v2Proxy.baseURI());
        console.log("- Contract owner:", v2Proxy.owner());
        console.log("Pre and post upgrade state consistency verification passed");
        
        // Test new functionality after upgrade
        vm.startPrank(user1);
        uint256 price = 1 ether;
        uint256 nonce = 1;
        
        // Create signature
        bytes32 messageHash = keccak256(abi.encodePacked(
            "\x19\x01",
            keccak256(abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("UpgradableNFT")),
                keccak256(bytes("2")),
                block.chainid,
                address(v2Proxy)
            )),
            keccak256(abi.encode(
                keccak256("Listing(uint256 tokenId,uint256 price,uint256 nonce)"),
                tokenId1,
                price,
                nonce
            ))
        ));
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user1PrivateKey(), messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        // Execute signature listing
        v2Proxy.listNFTWithSignature(tokenId1, price, nonce, signature);
        
        // Verify new functionality
        UpgradableNFTV2.ListingInfo memory listingInfo = v2Proxy.getListingInfo(tokenId1);
        assertTrue(listingInfo.isListed);
        assertEq(listingInfo.price, price);
        assertEq(listingInfo.seller, user1);
        
        console.log("New functionality after upgrade test passed");
        
        vm.stopPrank();
    }

    /// @notice Test unlist NFT functionality
    function testUnlistNFT() public {
        console.log("=== Testing Unlist NFT Functionality ===");
        
        // First upgrade to V2 and list NFT
        _upgradeToV2();
        _listNFT();
        
        // Switch to user1 to unlist
        vm.startPrank(user1);
        
        uint256 tokenId = 1;
        
        // Expect event
        vm.expectEmit(true, true, false, true);
        emit NFTUnlisted(tokenId, user1);
        
        // Execute unlist
        v2Proxy.unlistNFT(tokenId);
        
        // Verify unlist result
        UpgradableNFTV2.ListingInfo memory listingInfo = v2Proxy.getListingInfo(tokenId);
        assertFalse(listingInfo.isListed);
        
        console.log("Unlist NFT functionality test passed");
        
        vm.stopPrank();
    }

    /// @notice Test error cases
    function testErrorCases() public {
        console.log("=== Testing Error Cases ===");
        
        _upgradeToV2();
        
        // Test non-owner trying to list
        vm.startPrank(user2);
        uint256 tokenId = 1;
        uint256 price = 1 ether;
        uint256 nonce = 1;
        
        // First mint an NFT to user1
        vm.stopPrank();
        vm.startPrank(owner);
        v2Proxy.mintWithURI(user1, TOKEN_URI);
        vm.stopPrank();
        vm.startPrank(user2);
        
        // Create invalid signature (using wrong private key)
        bytes32 structHash = keccak256(abi.encode(
            keccak256("Listing(uint256 tokenId,uint256 price,uint256 nonce)"),
            tokenId,
            price,
            nonce
        ));
        
        bytes32 domainSeparator = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("UpgradableNFT")),
            keccak256(bytes("2")),
            block.chainid,
            address(v2Proxy)
        ));
        
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user2PrivateKey(), hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        // Should fail because user2 is not the owner of tokenId 1
        vm.expectRevert("Not owner");
        v2Proxy.listNFTWithSignature(tokenId, price, nonce, signature);
        
        console.log("Non-owner listing error test passed");
        
        vm.stopPrank();
    }

    /// @notice Helper function: upgrade to V2
    function _upgradeToV2() internal {
        vm.startPrank(owner);
        v1Proxy.upgradeToAndCall(address(v2Implementation), "");
        v2Proxy = UpgradableNFTV2(address(proxy));
        v2Proxy.upgradeV2();
        vm.stopPrank();
    }

    /// @notice Helper function: list NFT
    function _listNFT() internal {
        // First mint NFT
        vm.startPrank(owner);
        v2Proxy.mintWithURI(user1, TOKEN_URI);
        vm.stopPrank();
        
        // List NFT
        vm.startPrank(user1);
        uint256 tokenId = 1;
        uint256 price = 1 ether;
        uint256 nonce = 1;
        
        // Create signature using EIP712
        bytes32 structHash = keccak256(abi.encode(
            keccak256("Listing(uint256 tokenId,uint256 price,uint256 nonce)"),
            tokenId,
            price,
            nonce
        ));
        
        bytes32 domainSeparator = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("UpgradableNFT")),
            keccak256(bytes("2")),
            block.chainid,
            address(v2Proxy)
        ));
        
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user1PrivateKey(), hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        v2Proxy.listNFTWithSignature(tokenId, price, nonce, signature);
        vm.stopPrank();
    }

    /// @notice Get user1's private key (for signing)
    function user1PrivateKey() internal pure returns (uint256) {
        // This is a test private key corresponding to address 0x2
        return 0x2;
    }

    /// @notice Get user2's private key (for signing)
    function user2PrivateKey() internal pure returns (uint256) {
        // This is a test private key corresponding to address 0x3
        return 0x3;
    }
}