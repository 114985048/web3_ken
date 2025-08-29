// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
 
import "forge-std/Test.sol"; 
import "../src/MyToken.sol"; 
import "../src/TokenBank.sol"; 
 
contract TokenBankTest is Test {
    MyToken token;
    TokenBank bank;
    address user = vm.addr(1);  // 测试用户 (私钥=1)
    uint256 constant AMOUNT = 100e18;
 
    function setUp() public {
        token = new MyToken();
        bank = new TokenBank(address(token));
        token.transfer(user,  AMOUNT); // 给用户分配代币
    }
 
    function testPermitDeposit() public {
        vm.startPrank(user); 
 
        // 生成 Permit 签名 
        uint256 deadline = block.timestamp  + 1;
        (uint8 v, bytes32 r, bytes32 s) = _getPermitSignature(AMOUNT,deadline);
        
        // 调用 permitDeposit 
        bank.permitDeposit(AMOUNT,  block.timestamp  + 1 hours, v, r, s);
 
        // 验证结果 
        assertEq(token.balanceOf(user),  0, "user balance should jianshao");
        assertEq(bank.balances(user),  AMOUNT, "store should update");
    }
 
    function testExpiredPermit() public {
        uint256 deadline = block.timestamp  + 1;
        (uint8 v, bytes32 r, bytes32 s) = _getPermitSignature(AMOUNT, deadline);
        
        vm.warp(deadline  + 1); // 时间过期 
        vm.expectRevert("ERC20Permit:  expired deadline");
        bank.permitDeposit(AMOUNT,  deadline, v, r, s);
    }
 
    // 辅助函数：生成签名 
    function _getPermitSignature(uint256 amount, uint256 deadline) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        if (deadline == 0) deadline = block.timestamp  + 1 hours;
        
        bytes32 digest = keccak256(
            abi.encodePacked( 
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode( 
                        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                        user,
                        address(bank),
                        amount,
                        token.nonces(user), 
                        deadline 
                    )
                )
            )
        );
        return vm.sign(1,  digest); // 私钥=1 对应用户地址
    }
}