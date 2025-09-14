// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Bank.sol";

// 银行合约测试
contract BankTest is Test {
    Bank bank;
    address owner = address(0x123); // 合约所有者地址
    address user = address(0x456);  // 普通用户地址

    // 测试前的初始化设置
    function setUp() public {
        // 部署合约，设置触发阈值为10 ether
        vm.deal(owner, 100 ether); // 为所有者账户充值100 ether
        vm.deal(user, 100 ether);  // 为用户账户充值100 ether
        vm.prank(owner);           // 模拟所有者调用
        bank = new Bank(10 ether); // 创建银行合约实例
    }

    // 测试存款低于阈值的情况
    function testDepositBelowThreshold() public {
        // 用户存入低于阈值的金额（5 ether）
        vm.startPrank(user);              // 模拟用户调用
        bank.deposit{value: 5 ether}();   // 存款5 ether
        vm.stopPrank();                   // 停止模拟

        // checkUpkeep应该返回false，因为存款未达到阈值
        (bool upkeepNeeded, ) = bank.checkUpkeep("");
        assertFalse(upkeepNeeded, "Should not trigger upkeep"); // 断言不应该触发自动转账
    }

    // 测试存款超过阈值并执行自动转账的情况
    function testDepositAboveThresholdAndPerformUpkeep() public {
        // 用户存入超过阈值的金额（20 ether）
        vm.startPrank(user);               // 模拟用户调用
        bank.deposit{value: 20 ether}();   // 存款20 ether
        vm.stopPrank();                    // 停止模拟

        // checkUpkeep应该返回true，因为存款已超过阈值
        (bool upkeepNeeded, ) = bank.checkUpkeep("");
        assertTrue(upkeepNeeded, "Should trigger upkeep"); // 断言应该触发自动转账

        uint256 ownerBalanceBefore = owner.balance; // 记录所有者转账前的余额

        // 模拟keeper调用performUpkeep执行自动转账
        vm.prank(owner);         // 模拟所有者调用
        bank.performUpkeep("");  // 执行自动转账

        uint256 ownerBalanceAfter = owner.balance; // 记录所有者转账后的余额

        // 20 ether的一半是10 ether，应该被转移到所有者账户
        assertEq(ownerBalanceAfter - ownerBalanceBefore, 10 ether, "Owner should receive 10 ether");
    }

    // 测试多次存款并自动转账的情况
    function testMultipleDepositsAndAutoTransfer() public {
        // 第一次存款，金额低于阈值（8 ether）
        vm.startPrank(user);             // 模拟用户调用
        bank.deposit{value: 8 ether}();  // 存款8 ether
        vm.stopPrank();                  // 停止模拟

        (bool upkeepNeeded1, ) = bank.checkUpkeep("");
        assertFalse(upkeepNeeded1, "Should not trigger after first deposit"); // 断言第一次存款后不应该触发

        // 第二次存款，使得总金额超过阈值（5 ether）
        vm.startPrank(user);             // 模拟用户调用
        bank.deposit{value: 5 ether}();  // 存款5 ether
        vm.stopPrank();                  // 停止模拟

        (bool upkeepNeeded2, ) = bank.checkUpkeep("");
        assertTrue(upkeepNeeded2, "Should trigger after second deposit"); // 断言第二次存款后应该触发

        uint256 ownerBalanceBefore = owner.balance; // 记录所有者转账前的余额

        vm.prank(owner);         // 模拟所有者调用
        bank.performUpkeep("");  // 执行自动转账

        uint256 ownerBalanceAfter = owner.balance; // 记录所有者转账后的余额

        // 合约余额为13 ether，一半是6.5 ether，应该被转移给所有者
        assertEq(ownerBalanceAfter - ownerBalanceBefore, 6.5 ether, "Owner should receive 6.5 ether");
    }
}