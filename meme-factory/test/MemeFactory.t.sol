// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Meme_Factory.sol";

contract MemeFactoryTest is Test {
    Meme_Factory public factory;
    address public projectOwner;
    address public creator;
    address public buyer;
    
    // 测试参数
    string constant SYMBOL = "MEME";
    uint256 constant TOTAL_SUPPLY = 1000000 * 10**18; // 1,000,000 tokens
    uint256 constant PER_MINT = 100 * 10**18;       // 1,000 tokens per mint
    uint256 constant PRICE = 1 ether;           // 0.0001 ETH per token
    
    function setUp() public {
        console.log("=== Starting Test Setup ===");
        
        projectOwner = makeAddr("projectOwner");
        creator = makeAddr("creator");
        buyer = makeAddr("buyer");
        
        console.log("Project Owner Address:", projectOwner);
        console.log("Creator Address:", creator);
        console.log("Buyer Address:", buyer);
        
        // 给测试账户一些 ETH
        vm.deal(creator, 1000 ether);
        vm.deal(buyer, 1000 ether);
        
        console.log("Creator Initial Balance:", creator.balance / 1e18, "ETH");
        console.log("Buyer Initial Balance:", buyer.balance / 1e18, "ETH");
        
        // 部署工厂合约
        factory = new Meme_Factory(projectOwner);
        console.log("Factory Contract Deployed, Address:", address(factory));
        console.log("Project Fee Percentage:", factory.PROJECT_FEE_PERCENT(), "%");
        
        console.log("=== Test Setup Complete ===\n");
    }
    
    function testDeployInscription() public {
        console.log("=== Starting Token Deployment Test ===");
        console.log("Token Symbol:", SYMBOL);
        console.log("Total Supply:", TOTAL_SUPPLY / 1e18, "tokens");
        console.log("Per Mint Amount:", PER_MINT / 1e18, "tokens");
        console.log("Token Price:", PRICE / 1e18, "ETH");
        
        vm.startPrank(creator);
        
        address tokenAddr = factory.deployInscription(
            SYMBOL,
            TOTAL_SUPPLY,
            PER_MINT,
            PRICE
        );
        
        vm.stopPrank();
        
        console.log("Token Contract Deployed Successfully, Address:", tokenAddr);
        
        // 验证代币部署成功
        assertTrue(factory.deployedTokens(tokenAddr), "Token not deployed");
        console.log("Token Deployment Verification Passed");
        
        // 验证代币参数
        MemeToken token = MemeToken(tokenAddr);
        assertEq(token.totalSupply_(), TOTAL_SUPPLY, "Incorrect total supply");
        assertEq(token.perMint(), PER_MINT, "Incorrect per mint amount");
        assertEq(token.price(), PRICE, "Incorrect price");
        assertEq(token.memeCreator(), creator, "Incorrect creator");
        
        console.log("Token Parameters Verification Passed:");
        console.log("  - Total Supply:", token.totalSupply_() / 1e18, "tokens");
        console.log("  - Per Mint Amount:", token.perMint() / 1e18, "tokens");
        console.log("  - Token Price:", token.price() / 1e18, "ETH");
        console.log("  - Creator Address:", token.memeCreator());
        console.log("=== Token Deployment Test Complete ===\n");
    }
    
    function testMintInscription() public {
        console.log("=== Starting Token Minting Test ===");
        
        // 部署代币
        vm.startPrank(creator);
        address tokenAddr = factory.deployInscription(
            SYMBOL,
            TOTAL_SUPPLY,
            PER_MINT,
            PRICE
        );
        vm.stopPrank();
        
        console.log("Token Contract Address:", tokenAddr);
        
        // 记录初始余额
        uint256 initialProjectBalance = projectOwner.balance;
        uint256 initialCreatorBalance = creator.balance;
        uint256 initialBuyerBalance = buyer.balance;
        
        console.log("Balances Before Minting:");
        console.log("  Project Owner Balance:", initialProjectBalance / 1e18, "ETH");
        console.log("  Creator Balance:", initialCreatorBalance / 1e18, "ETH");
        console.log("  Buyer Balance:", initialBuyerBalance / 1e18, "ETH");
        
        // 计算所需支付金额
        uint256 requiredAmount = PER_MINT * PRICE / 10**18;
        console.log("Required Payment Amount:", requiredAmount / 1e18, "ETH");
        
        // 买家铸造代币
        console.log("Starting Token Minting...");
        vm.startPrank(buyer);
        factory.mintInscription{value: requiredAmount}(tokenAddr);
        vm.stopPrank();
        console.log("Token Minting Complete");
        
        // 验证代币铸造成功
        MemeToken token = MemeToken(tokenAddr);
        assertEq(token.balanceOf(buyer), PER_MINT, "Incorrect minted amount");
        assertEq(token.mintedAmount(), PER_MINT, "Incorrect total minted amount");
        
        console.log("Minting Verification Passed:");
        console.log("  Buyer Token Balance:", token.balanceOf(buyer) / 1e18, "tokens");
        console.log("  Total Minted Amount:", token.mintedAmount() / 1e18, "tokens");
        
        // 验证费用分配
        uint256 projectFee = (requiredAmount * factory.PROJECT_FEE_PERCENT()) / 100;
        uint256 creatorFee = requiredAmount - projectFee;
        
        console.log("Fee Distribution Calculation:");
        console.log("  Project Fee (ETH):", projectFee / 1e18);
        console.log("  Project Fee Percentage:", factory.PROJECT_FEE_PERCENT());
        console.log("  Creator Fee (ETH):", creatorFee / 1e18);
        
        assertEq(projectOwner.balance, initialProjectBalance + projectFee, "Incorrect project fee");
        assertEq(creator.balance, initialCreatorBalance + creatorFee, "Incorrect creator fee");
        
        console.log("Balances After Minting:");
        console.log("  Project Owner Balance (ETH):", projectOwner.balance / 1e18);
        console.log("  Project Owner Balance Change (ETH):", (projectOwner.balance - initialProjectBalance) / 1e18);
        console.log("  Creator Balance (ETH):", creator.balance / 1e18);
        console.log("  Creator Balance Change (ETH):", (creator.balance - initialCreatorBalance) / 1e18);
        console.log("  Buyer Balance (ETH):", buyer.balance / 1e18);
        console.log("  Buyer Balance Change (ETH):", (initialBuyerBalance - buyer.balance) / 1e18);
        
        console.log("=== Token Minting Test Complete ===\n");
    }
    
    function testMintMultipleTimes() public {
        console.log("=== Starting Multiple Minting Test ===");
        
        // 部署代币
        vm.startPrank(creator);
        address tokenAddr = factory.deployInscription(
            SYMBOL,
            TOTAL_SUPPLY,
            PER_MINT,
            PRICE
        );
        vm.stopPrank();
        
        console.log("Token Contract Address:", tokenAddr);
        
        // 计算所需支付金额
        uint256 requiredAmount = PER_MINT * PRICE / 10**18;
        console.log("Required Payment Per Mint:", requiredAmount / 1e18, "ETH");
        
        // 多次铸造，但限制次数以避免超过总供应量
        // 由于 TOTAL_SUPPLY = 1,000,000 * 10**18 且 PER_MINT = 1,000 * 10**18
        // 理论上最多可以铸造 1000 次，但为安全起见，我们只铸造几次进行测试
        uint256 testMints = 5; // 只测试铸造 5 次，避免测试耗时过长
        console.log("Planned Minting Times:", testMints);
        
        MemeToken token = MemeToken(tokenAddr);
        console.log("Starting Batch Minting...");
        
        for (uint256 i = 0; i < testMints; i++) {
            console.log("  Minting Round", i + 1, "...");
            
            vm.startPrank(buyer);
            factory.mintInscription{value: requiredAmount}(tokenAddr);
            vm.stopPrank();
            
            // 验证铸造数量
            assertEq(token.mintedAmount(), PER_MINT * (i + 1), "Incorrect total minted amount");
            
            console.log("    Current Total Minted:", token.mintedAmount() / 1e18, "tokens");
            console.log("    Buyer Token Balance:", token.balanceOf(buyer) / 1e18, "tokens");
        }
        
        console.log("Batch Minting Complete, Total Minted:", token.mintedAmount() / 1e18, "tokens");
        
        // 验证可以继续铸造（因为我们只铸造了少量代币）
        console.log("Verifying Can Continue Minting...");
        vm.startPrank(buyer);
        factory.mintInscription{value: requiredAmount}(tokenAddr);
        vm.stopPrank();
        
        // 验证铸造后的总量
        assertEq(token.mintedAmount(), PER_MINT * (testMints + 1), "Incorrect final minted amount");
        
        console.log("Final Verification Passed:");
        console.log("  Final Total Minted:", token.mintedAmount() / 1e18, "tokens");
        console.log("  Buyer Final Token Balance:", token.balanceOf(buyer) / 1e18, "tokens");
        console.log("  Total Minting Times:", testMints + 1);
        
        console.log("=== Multiple Minting Test Complete ===\n");
    }
}