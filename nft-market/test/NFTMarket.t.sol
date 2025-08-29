// test/NFTMarket.t.sol  
pragma solidity ^0.8.20;
 
import "forge-std/Test.sol"; 
import "../src/NFTMarket.sol"; 

contract NFTMarketTest is Test {
    MyToken token;
    MyNFT nft;
    NFTMarket market;
    
    // 测试账户
    address admin = vm.addr(1);        // 合约部署者
    address signer = vm.addr(2);       // 签名授权地址 
    address seller = vm.addr(3);       // NFT卖家
    address buyer = vm.addr(4);        // 授权买家
    address unauthorized = vm.addr(5);  // 未授权买家
    
    function setUp() public {
        console.log("=== Setting up test environment ===");
        console.log("Admin address:", admin);
        console.log("Signer address:", signer);
        console.log("Seller address:", seller);
        console.log("Buyer address:", buyer);
        console.log("Unauthorized address:", unauthorized);
        
        vm.startPrank(admin); 
        // 部署合约
        token = new MyToken(1000000 ether); // 100万代币
        nft = new MyNFT("CryptoPunks", "PUNK"); // 自定义NFT名称和符号
        market = new NFTMarket(address(token), address(nft), signer);
        
        console.log("Contract deployment completed:");
        console.log("  - MyToken address:", address(token));
        console.log("  - MyNFT address:", address(nft));
        console.log("  - NFTMarket address:", address(market));
        
        // 分配初始代币
        token.transfer(seller,  1000 ether);
        token.transfer(buyer,  1000 ether);
        token.transfer(unauthorized,  1000 ether);
        
        console.log("Initial token distribution completed:");
        console.log("  - Seller balance:", token.balanceOf(seller) / 1e18, "ETH");
        console.log("  - Buyer balance:", token.balanceOf(buyer) / 1e18, "ETH");
        console.log("  - Unauthorized address balance:", token.balanceOf(unauthorized) / 1e18, "ETH");
        
        // Seller mints NFTs
        vm.stopPrank(); 
        vm.startPrank(seller); 
        nft.mint(seller);  // tokenId 0
        nft.mint(seller);  // tokenId 1
        vm.stopPrank(); 
        
        console.log("NFT minting completed:");
        console.log("  - tokenId 0 owner:", nft.ownerOf(0));
        console.log("  - tokenId 1 owner:", nft.ownerOf(1));
        console.log("  - Seller NFT count:", nft.ownerOf(0) == seller ? 2 : 0);
        console.log("=== Test environment setup completed ===\n");
    }
    
    // Test normal purchase flow
    function testNormalBuy() public {
        console.log("=== Starting normal purchase flow test ===");
        uint256 tokenId = 0;
        uint256 price = 100 ether;
        
        console.log("Test parameters:");
        console.log("  - NFT tokenId:", tokenId);
        console.log("  - Price:", price / 1e18, "ETH");
        
        // Record pre-purchase state
        console.log("Pre-purchase state:");
        console.log("  - NFT owner:", nft.ownerOf(tokenId));
        console.log("  - Seller balance:", token.balanceOf(seller) / 1e18, "ETH");
        console.log("  - Buyer balance:", token.balanceOf(buyer) / 1e18, "ETH");
        console.log("  - Buyer allowance:", token.allowance(buyer, address(market)) / 1e18, "ETH");
        
        // Seller lists NFT
        vm.startPrank(seller); 
        nft.approve(address(market),  tokenId);
        market.list(tokenId,  price);
        vm.stopPrank(); 
        
        console.log("NFT listing completed:");
        console.log("  - NFT approved to market contract");
        console.log("  - NFT listed with price:", price / 1e18, "ETH");
        
        // Buyer approves and purchases
        vm.startPrank(buyer); 
        token.approve(address(market),  price);
        console.log("Buyer approval completed, allowance:", token.allowance(buyer, address(market)) / 1e18, "ETH");
        
        market.buyNFT(tokenId); 
        vm.stopPrank(); 
        
        console.log("NFT purchase completed!");
        
        // Verify results
        console.log("Post-purchase state:");
        console.log("  - NFT new owner:", nft.ownerOf(tokenId));
        console.log("  - Seller new balance:", token.balanceOf(seller) / 1e18, "ETH");
        console.log("  - Buyer new balance:", token.balanceOf(buyer) / 1e18, "ETH");
        
        assertEq(nft.ownerOf(tokenId),  buyer, "NFT ownership should transfer to buyer");
        assertEq(token.balanceOf(seller),  1000 ether + price, "Seller should receive payment");
        assertEq(token.balanceOf(buyer),  1000 ether - price, "Buyer balance should decrease");
        
        console.log("Normal purchase flow test passed\n");
    }
    
    // Test permit-based purchase (whitelist)
    function testPermitBuy() public {
        console.log("=== Starting permit-based purchase test (whitelist) ===");
        uint256 tokenId = 1;
        uint256 price = 150 ether;
        uint256 deadline = block.timestamp  + 1 days;
        
        console.log("Test parameters:");
        console.log("  - NFT tokenId:", tokenId);
        console.log("  - Price:", price / 1e18, "ETH");
        console.log("  - Permit deadline:", deadline);
        console.log("  - Current time:", block.timestamp);
        
        // Record pre-purchase state
        console.log("Pre-purchase state:");
        console.log("  - NFT owner:", nft.ownerOf(tokenId));
        console.log("  - Seller balance:", token.balanceOf(seller) / 1e18, "ETH");
        console.log("  - Buyer balance:", token.balanceOf(buyer) / 1e18, "ETH");
        console.log("  - Buyer current nonce:", market.nonces(buyer));
        
        // Seller lists NFT
        vm.startPrank(seller); 
        nft.approve(address(market),  tokenId);
        market.list(tokenId,  price);
        vm.stopPrank(); 
        
        console.log("NFT listing completed:");
        console.log("  - NFT approved to market contract");
        console.log("  - NFT listed with price:", price / 1e18, "ETH");
        
        // Get current nonce
        uint256 nonce = market.nonces(buyer); 
        console.log("Preparing signature permit, current nonce:", nonce);
        
        // Prepare signature message
        bytes32 digest = keccak256(
            abi.encodePacked( 
                "\x19\x01",
                market.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode( 
                        keccak256("PermitBuy(address buyer,uint256 tokenId,uint256 nonce,uint256 deadline)"),
                        buyer,
                        tokenId,
                        nonce,
                        deadline 
                    )
                )
            )
        );
        
        // Sign with project private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(2,  digest); // signer is vm.addr(2) 
        console.log("Signature completed:");
        console.log("  - Signer:", signer);
        console.log("  - Signature v:", v);
        console.log("  - Signature r:", uint256(r));
        console.log("  - Signature s:", uint256(s));
        
        // Buyer executes permit-based purchase
        vm.startPrank(buyer); 
        token.approve(address(market),  price);
        console.log("Buyer approval completed, allowance:", token.allowance(buyer, address(market)) / 1e18, "ETH");
        
        market.permitBuy(tokenId,  deadline, abi.encodePacked(r,  s, v));
        vm.stopPrank(); 
        
        console.log("NFT permit-based purchase completed!");
        
        // Verify results
        console.log("Post-purchase state:");
        console.log("  - NFT new owner:", nft.ownerOf(tokenId));
        console.log("  - New nonce:", market.nonces(buyer));
        console.log("  - Seller new balance:", token.balanceOf(seller) / 1e18, "ETH");
        console.log("  - Buyer new balance:", token.balanceOf(buyer) / 1e18, "ETH");
        
        assertEq(nft.ownerOf(tokenId),  buyer, "NFT should be transferred to buyer");
        assertEq(market.nonces(buyer),  nonce + 1, "Nonce should increment");
        assertEq(token.balanceOf(seller),  1000 ether + price, "Seller should receive payment");
        
        console.log("Permit-based purchase test passed\n");
    }
    
    // Test unauthorized user attempting to purchase
    function testUnauthorizedBuy() public {
        console.log("=== Starting unauthorized user purchase test ===");
        uint256 tokenId = 1;
        uint256 price = 150 ether;
        uint256 deadline = block.timestamp  + 1 days;
        
        console.log("Test parameters:");
        console.log("  - NFT tokenId:", tokenId);
        console.log("  - Price:", price / 1e18, "ETH");
        console.log("  - Permit deadline:", deadline);
        
        // Record pre-purchase state
        console.log("Pre-purchase state:");
        console.log("  - NFT owner:", nft.ownerOf(tokenId));
        console.log("  - Buyer balance:", token.balanceOf(buyer) / 1e18, "ETH");
        console.log("  - Buyer current nonce:", market.nonces(buyer));
        
        // Seller lists NFT
        vm.startPrank(seller); 
        nft.approve(address(market),  tokenId);
        market.list(tokenId,  price);
        vm.stopPrank(); 
        
        console.log("NFT listing completed");
        
        // Get current nonce
        uint256 nonce = market.nonces(buyer); 
        console.log("Preparing signature permit, current nonce:", nonce);
        
        // Use unauthorized address signature
        bytes32 digest = keccak256(
            abi.encodePacked( 
                "\x19\x01",
                market.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode( 
                        keccak256("PermitBuy(address buyer,uint256 tokenId,uint256 nonce,uint256 deadline)"),
                        buyer,
                        tokenId,
                        nonce,
                        deadline 
                    )
                )
            )
        );
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(5,  digest); // unauthorized is vm.addr(5) 
        console.log("Using unauthorized address signature:");
        console.log("  - Signer:", unauthorized);
        console.log("  - Signature v:", v);
        console.log("  - Signature r:", uint256(r));
        console.log("  - Signature s:", uint256(s));
        
        // Attempt to purchase (should fail)
        vm.startPrank(buyer); 
        token.approve(address(market),  price);
        console.log("Buyer approval completed, attempting purchase with invalid signature...");
        
        vm.expectRevert("Invalid signature");
        market.permitBuy(tokenId,  deadline, abi.encodePacked(r,  s, v));
        vm.stopPrank(); 
        
        console.log("Unauthorized purchase test passed - failed as expected\n");
    }
    
    // 测试过期授权 
    function testExpiredPermit() public {
        console.log("=== Starting expired permit test ===");
        uint256 tokenId = 1;
        uint256 price = 150 ether;
        uint256 deadline = block.timestamp  + 1 hours;
        
        console.log("Test parameters:");
        console.log("  - NFT tokenId:", tokenId);
        console.log("  - Price:", price / 1e18, "ETH");
        console.log("  - Permit deadline:", deadline);
        console.log("  - Current time:", block.timestamp);
        
        // 记录购买前状态
        console.log("Pre-purchase state:");
        console.log("  - NFT owner:", nft.ownerOf(tokenId));
        console.log("  - Buyer balance:", token.balanceOf(buyer) / 1e18, "ETH");
        console.log("  - Buyer current nonce:", market.nonces(buyer));
        
        // 卖家上架NFT 
        vm.startPrank(seller); 
        nft.approve(address(market),  tokenId);
        market.list(tokenId,  price);
        vm.stopPrank(); 
        
        console.log("NFT listing completed");
        
        // 获取当前nonce
        uint256 nonce = market.nonces(buyer); 
        console.log("Preparing signature permit, current nonce:", nonce);
        
        // 准备签名
        bytes32 digest = keccak256(
            abi.encodePacked( 
                "\x19\x01",
                market.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode( 
                        keccak256("PermitBuy(address buyer,uint256 tokenId,uint256 nonce,uint256 deadline)"),
                        buyer,
                        tokenId,
                        nonce,
                        deadline 
                    )
                )
            )
        );
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(2,  digest);
        console.log("Signature completed:");
        console.log("  - Signer:", signer);
        console.log("  - Signature v:", v);
        console.log("  - Signature r:", uint256(r));
        console.log("  - Signature s:", uint256(s));
        
        // 时间快进
        console.log("Time before warp:", block.timestamp);
        vm.warp(deadline  + 1);
        console.log("Time after warp:", block.timestamp);
        console.log("Permit expired, attempting purchase...");
        
        // 尝试购买(应失败)
        vm.startPrank(buyer); 
        token.approve(address(market),  price);
        vm.expectRevert("Permission expired");
        market.permitBuy(tokenId,  deadline, abi.encodePacked(r,  s, v));
        vm.stopPrank(); 
        
        console.log("Expired permit test passed - failed as expected\n");
    }
}