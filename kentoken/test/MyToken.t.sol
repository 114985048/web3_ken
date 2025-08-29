// SPDX-License-Identifier: MIT  
pragma solidity ^0.8.0;
import "forge-std/Test.sol"; 
import "../src/MyToken.sol"; 
 
contract MyTokenTest is Test {
    MyToken token;
    address owner = address(1);
    address spender = address(2);
 
    function setUp() public {
        vm.prank(owner); 
        token = new MyToken(); // 部署代币合约 
    }
 
    // 测试基础 ERC-20 功能
    function testMint() public {
        assertEq(token.balanceOf(owner),  1000000 * 10 ** 18);
    }
 
    // 测试 EIP-2612 Permit 功能
    function testPermit() public {
        // 1. 准备签名数据
        uint256 privateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80; // 替换为测试用私钥（如 vm.envUint("PRIVATE_KEY") ）
        address signer = vm.addr(privateKey); 
        uint256 amount = 1000;
        uint256 deadline = block.timestamp  + 1 hours;
 
        // 2. 获取当前 nonce 
        uint256 nonce = token.nonces(signer); 
 
        // 3. 生成签名（使用 Foundry 的辅助函数）
        bytes32 digest = keccak256(
            abi.encodePacked( 
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode( 
                        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                        signer,
                        spender,
                        amount,
                        nonce,
                        deadline
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey,  digest);
 
        // 4. 调用 permit 
        token.permit(signer,  spender, amount, deadline, v, r, s);
 
        // 5. 验证授权是否成功 
        assertEq(token.allowance(signer,  spender), amount);
    }
}