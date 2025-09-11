// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;
    
    // 测试用户地址
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public user3 = address(0x3);
    address public user4 = address(0x4);
    address public user5 = address(0x5);
    address public user6 = address(0x6);
    address public user7 = address(0x7);
    address public user8 = address(0x8);
    address public user9 = address(0x9);
    address public user10 = address(0xa);
    address public user11 = address(0xb);
    address public user12 = address(0xc);

    function setUp() public {
        bank = new Bank();
        
        // 给测试用户一些 ETH
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);
        vm.deal(user4, 100 ether);
        vm.deal(user5, 100 ether);
        vm.deal(user6, 100 ether);
        vm.deal(user7, 100 ether);
        vm.deal(user8, 100 ether);
        vm.deal(user9, 100 ether);
        vm.deal(user10, 100 ether);
        vm.deal(user11, 100 ether);
        vm.deal(user12, 100 ether);
    }

    // 测试基本存款功能
    function testDeposit() public {
        // 用户1存款 1 ETH
        vm.prank(user1);
        (bool success,) = address(bank).call{value: 1 ether}("");
        assertTrue(success);
        
        // 验证余额
        assertEq(bank.balances(user1), 1 ether);
        
        // 验证前10名列表
        (address[] memory users, uint256[] memory amounts) = bank.getTop10();
        assertEq(users.length, 1);
        assertEq(users[0], user1);
        assertEq(amounts[0], 1 ether);
        assertEq(bank.topCount(), 1);
        assertEq(bank.head(), user1);
        assertEq(bank.tail(), user1);
    }

    // 测试多次存款
    function testMultipleDeposits() public {
        // 用户1存款 1 ETH
        vm.prank(user1);
        (bool success,) = address(bank).call{value: 1 ether}("");
        assertTrue(success);
        
        // 用户1再次存款 2 ETH
        vm.prank(user1);
        (success,) = address(bank).call{value: 2 ether}("");
        assertTrue(success);
        
        // 验证总余额
        assertEq(bank.balances(user1), 3 ether);
        
        // 验证前10名列表
        (address[] memory users, uint256[] memory amounts) = bank.getTop10();
        assertEq(users.length, 1);
        assertEq(users[0], user1);
        assertEq(amounts[0], 3 ether);
    }

    // 测试前10名用户列表管理
    function testTop10List() public {
        // 按不同金额存款
        vm.prank(user1);
        (bool success,) = address(bank).call{value: 5 ether}("");
        assertTrue(success);
        
        vm.prank(user2);
        (success,) = address(bank).call{value: 3 ether}("");
        assertTrue(success);
        
        vm.prank(user3);
        (success,) = address(bank).call{value: 7 ether}("");
        assertTrue(success);
        
        vm.prank(user4);
        (success,) = address(bank).call{value: 1 ether}("");
        assertTrue(success);
        
        // 验证前10名列表（应该按金额降序排列）
        (address[] memory users, uint256[] memory amounts) = bank.getTop10();
        assertEq(users.length, 4);
        assertEq(users[0], user3); // 7 ETH
        assertEq(amounts[0], 7 ether);
        assertEq(users[1], user1); // 5 ETH
        assertEq(amounts[1], 5 ether);
        assertEq(users[2], user2); // 3 ETH
        assertEq(amounts[2], 3 ether);
        assertEq(users[3], user4); // 1 ETH
        assertEq(amounts[3], 1 ether);
        
        // 验证链表头部和尾部
        assertEq(bank.head(), user3);
        assertEq(bank.tail(), user4);
        assertEq(bank.topCount(), 4);
    }

    // 测试超过10个用户的情况
    function testMoreThan10Users() public {
        // 创建11个用户，每个存款不同金额
        address[] memory users = new address[](11);
        uint256[] memory amounts = new uint256[](11);
        
        for (uint256 i = 0; i < 11; i++) {
            users[i] = address(uint160(0x100 + i));
            amounts[i] = (i + 1) * 1 ether;
            vm.deal(users[i], 100 ether);
            
            vm.prank(users[i]);
            (bool success,) = address(bank).call{value: amounts[i]}("");
            assertTrue(success);
        }
        
        // 验证只有前10名用户在前10名列表中
        (address[] memory topUsers, uint256[] memory topAmounts) = bank.getTop10();
        assertEq(topUsers.length, 10);
        assertEq(bank.topCount(), 10);
        
        // 验证前10名按金额降序排列
        for (uint256 i = 0; i < 9; i++) {
            assertTrue(topAmounts[i] >= topAmounts[i + 1]);
        }
        
        // 验证第11个用户（金额最小）不在前10名中
        bool found = false;
        for (uint256 i = 0; i < 10; i++) {
            if (topUsers[i] == users[0]) { // users[0] 存款最少
                found = true;
                break;
            }
        }
        assertFalse(found);
    }

    // 测试用户更新存款后在前10名中的位置变化
    function testUserPositionUpdate() public {
        // 先创建几个用户
        vm.prank(user1);
        (bool success,) = address(bank).call{value: 5 ether}("");
        assertTrue(success);
        
        vm.prank(user2);
        (success,) = address(bank).call{value: 3 ether}("");
        assertTrue(success);
        
        vm.prank(user3);
        (success,) = address(bank).call{value: 7 ether}("");
        assertTrue(success);
        
        // 验证初始顺序：user3(7) -> user1(5) -> user2(3)
        (address[] memory users, uint256[] memory amounts) = bank.getTop10();
        assertEq(users[0], user3);
        assertEq(users[1], user1);
        assertEq(users[2], user2);
        
        // user2 增加存款到 8 ETH，应该成为第一名
        vm.prank(user2);
        (success,) = address(bank).call{value: 5 ether}("");
        assertTrue(success);
        
        // 验证新顺序：user2(8) -> user3(7) -> user1(5)
        (users, amounts) = bank.getTop10();
        assertEq(users[0], user2);
        assertEq(amounts[0], 8 ether);
        assertEq(users[1], user3);
        assertEq(users[2], user1);
    }

    // 测试零金额存款
    function testZeroDeposit() public {
        vm.prank(user1);
        (bool success,) = address(bank).call{value: 0}("");
        assertFalse(success);
        
        // 验证用户余额仍为0
        assertEq(bank.balances(user1), 0);
        assertEq(bank.topCount(), 0);
    }

    // 测试链表插入和删除的边界情况
    function testLinkedListEdgeCases() public {
        // 测试单个用户
        vm.prank(user1);
        (bool success,) = address(bank).call{value: 1 ether}("");
        assertTrue(success);
        
        (address[] memory users, uint256[] memory amounts) = bank.getTop10();
        assertEq(users.length, 1);
        assertEq(bank.head(), user1);
        assertEq(bank.tail(), user1);
        
        // 添加第二个用户
        vm.prank(user2);
        (success,) = address(bank).call{value: 2 ether}("");
        assertTrue(success);
        
        (users, amounts) = bank.getTop10();
        assertEq(users.length, 2);
        assertEq(bank.head(), user2); // 金额更大
        assertEq(bank.tail(), user1);
        
        // 添加第三个用户，金额在中间
        vm.prank(user3);
        (success,) = address(bank).call{value: 1.5 ether}("");
        assertTrue(success);
        
        (users, amounts) = bank.getTop10();
        assertEq(users.length, 3);
        assertEq(users[0], user2); // 2 ETH
        assertEq(users[1], user3); // 1.5 ETH
        assertEq(users[2], user1); // 1 ETH
    }

    // 测试相同金额的用户
    function testSameAmountUsers() public {
        // 两个用户存款相同金额
        vm.prank(user1);
        (bool success,) = address(bank).call{value: 5 ether}("");
        assertTrue(success);
        
        vm.prank(user2);
        (success,) = address(bank).call{value: 5 ether}("");
        assertTrue(success);
        
        (address[] memory users, uint256[] memory amounts) = bank.getTop10();
        assertEq(users.length, 2);
        assertEq(amounts[0], 5 ether);
        assertEq(amounts[1], 5 ether);
        
        // 验证链表结构正确
        assertEq(bank.head(), user1); // 先插入的在前面
        assertEq(bank.tail(), user2);
    }

    // 测试合约余额
    function testContractBalance() public {
        uint256 initialBalance = address(bank).balance;
        
        vm.prank(user1);
        (bool success,) = address(bank).call{value: 1 ether}("");
        assertTrue(success);
        
        assertEq(address(bank).balance, initialBalance + 1 ether);
    }

    // 测试大量用户的情况
    function testManyUsers() public {
        // 创建20个用户
        for (uint256 i = 0; i < 20; i++) {
            address user = address(uint160(0x1000 + i));
            vm.deal(user, 100 ether);
            
            vm.prank(user);
            (bool success,) = address(bank).call{value: (i + 1) * 0.1 ether}("");
            assertTrue(success);
        }
        
        // 验证只有前10名在前10名列表中
        (address[] memory topUsers, uint256[] memory topAmounts) = bank.getTop10();
        assertEq(topUsers.length, 10);
        assertEq(bank.topCount(), 10);
        
        // 验证按金额降序排列
        for (uint256 i = 0; i < 9; i++) {
            assertTrue(topAmounts[i] >= topAmounts[i + 1]);
        }
        
        // 验证最小金额是 1.1 ether（第11个用户）
        assertTrue(topAmounts[9] >= 1.1 ether);
    }

    // 测试用户从列表中移除后重新插入
    function testUserReinsertion() public {
        // 创建11个用户，让第11个用户不在前10名中
        for (uint256 i = 0; i < 11; i++) {
            address testUser = address(uint160(0x2000 + i));
            vm.deal(testUser, 100 ether);
            
            vm.prank(testUser);
            (bool callSuccess,) = address(bank).call{value: (i + 1) * 1 ether}("");
            assertTrue(callSuccess);
        }
        
        // 验证第11个用户（存款11 ETH）在前10名中，第1个用户（存款1 ETH）不在前10名中
        (address[] memory topUsers, uint256[] memory topAmounts) = bank.getTop10();
        address testUser0 = address(uint160(0x2000)); // 存款1 ETH
        address testUser10 = address(uint160(0x2000 + 10)); // 存款11 ETH
        
        // 验证用户0（存款1 ETH）不在前10名中
        bool foundUser0 = false;
        for (uint256 i = 0; i < 10; i++) {
            if (topUsers[i] == testUser0) {
                foundUser0 = true;
                break;
            }
        }
        assertFalse(foundUser0);
        
        // 验证用户10（存款11 ETH）在前10名中
        bool foundUser10 = false;
        for (uint256 i = 0; i < 10; i++) {
            if (topUsers[i] == testUser10) {
                foundUser10 = true;
                break;
            }
        }
        assertTrue(foundUser10);
        
        // 用户0增加存款到 15 ETH，应该成为第一名
        vm.prank(testUser0);
        (bool callSuccess,) = address(bank).call{value: 14 ether}("");
        assertTrue(callSuccess);
        
        // 验证用户0现在是第一名
        (topUsers, topAmounts) = bank.getTop10();
        assertEq(topUsers[0], testUser0);
        assertEq(topAmounts[0], 15 ether);
    }
}
