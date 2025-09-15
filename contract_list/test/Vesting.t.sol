// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Vesting.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// 模拟 ERC20 代币合约，用于测试
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MCK") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// Vesting 合约测试套件
contract VestingTest is Test {
    MockERC20 token;
    Vesting vesting;
    address beneficiary = address(0xBEEF); // 受益人地址
    address deployer = address(0xDEAD);    // 部署者地址
    uint256 constant ONE_MILLION = 1_000_000 ether; // 100万代币

    // 测试初始化设置
    function setUp() public {
        vm.deal(deployer, 1 ether);
        vm.startPrank(deployer);

        token = new MockERC20();
        // 为部署者铸造100万代币
        token.mint(deployer, ONE_MILLION);
        console.log(unicode"部署者获得100万代币，当前余额: %d", token.balanceOf(deployer));

        // 部署 vesting 合约
        vesting = new Vesting(address(token), beneficiary);
        console.log(unicode"Vesting 合约部署完成，受益人地址: %s", beneficiary);

        // 将100万代币转入 vesting 合约（部署后立即转入）
        token.transfer(address(vesting), ONE_MILLION);
        console.log(unicode"向 Vesting 合约转入100万代币，合约余额: %d", token.balanceOf(address(vesting)));

        vm.stopPrank();
    }

    // 测试初始状态
    function testInitialState() public {
        console.log(unicode"=== 测试初始状态 ===");
        // 刚发完 token，合约持有 1,000,000，released = 0，cliff 未到，releasable 为 0
        uint256 contractBalance = token.balanceOf(address(vesting));
        uint256 releasableAmount = vesting.releasableAmount();
        console.log(unicode"合约余额: %d", contractBalance);
        console.log(unicode"可释放金额: %d", releasableAmount);
        assertEq(contractBalance, ONE_MILLION);
        assertEq(releasableAmount, 0);
        console.log(unicode"初始状态测试通过");
    }

    // 测试在 cliff 期之前无法释放代币
    function testCannotReleaseBeforeCliff() public {
        console.log(unicode"=== 测试 cliff 期前无法释放 ===");
        // 时间前进11个月（仍在12个月的cliff期之前）
        console.log(unicode"时间前进11个月");
        vm.warp(block.timestamp + 11 * 30 days);
        console.log(unicode"当前时间戳: %d, cliff时间戳: %d", block.timestamp, vesting.cliffTimestamp());
        vm.prank(beneficiary);
        // 期望调用 revert 并返回 "no tokens to release" 错误
        console.log(unicode"尝试在 cliff 期前释放代币，应失败");
        vm.expectRevert(bytes("no tokens to release"));
        vesting.release();
        console.log(unicode"cliff 期前释放测试通过");
    }

    // 测试第13个月的首次月度释放
    function testFirstMonthlyReleaseAtMonth13() public {
        console.log(unicode"=== 测试第13个月首次释放 ===");
        // 时间前进到第12个月后1秒（进入第13个月）
        console.log(unicode"时间前进到第13个月");
        vm.warp(block.timestamp + 12 * 30 days + 1);
        console.log(unicode"当前时间戳: %d", block.timestamp);
        // 可释放金额应等于总量的1/24
        uint256 total = token.balanceOf(address(vesting)); // 1,000,000
        uint256 expectedMonthShare = total / 24;
        uint256 releasableAmount = vesting.releasableAmount();
        console.log(unicode"总金额: %d", total);
        console.log(unicode"预期释放份额: %d", expectedMonthShare);
        console.log(unicode"实际可释放金额: %d", releasableAmount);
        assertEq(releasableAmount, expectedMonthShare);

        // 调用释放函数
        console.log(unicode"调用 release() 函数");
        vm.prank(beneficiary);
        vesting.release();
        uint256 beneficiaryBalance = token.balanceOf(beneficiary);
        console.log(unicode"受益人余额: %d", beneficiaryBalance);
        console.log(unicode"释放后可释放金额: %d", vesting.releasableAmount());
        // 检查受益人余额是否正确
        assertEq(beneficiaryBalance, expectedMonthShare);
        // 检查可释放金额是否归零
        assertEq(vesting.releasableAmount(), 0);
        console.log(unicode"第13个月释放测试通过");
    }

    // 测试每月释放直到全部释放完毕
    function testReleaseEveryMonthUntilFullyReleased() public {
        console.log(unicode"=== 测试每月释放直到完成 ===");
        uint256 total = token.balanceOf(address(vesting));
        uint256 monthShare = total / 24;
        console.log(unicode"总金额: %d, 每月份额: %d", total, monthShare);
        // 时间前进到首次可释放时刻
        uint256 t0 = block.timestamp;
        vm.warp(t0 + 12 * 30 days + 1);
        console.log(unicode"时间前进到首次可释放时刻");

        // 迭代24个月进行测试
        for (uint256 i = 0; i < 24; i++) {
            console.log(unicode"--- 第%d月释放 ---", i+1);
            // 计算预期已解锁金额和可释放金额
            uint256 expectedVested = monthShare * (i + 1);
            if (expectedVested > total) expectedVested = total;
            uint256 expectedReleasable = expectedVested - vesting.released();
            console.log(unicode"预期已解锁: %d, 已释放: %d, 预期可释放: %d", expectedVested, vesting.released(), expectedReleasable);

            // 执行释放操作
            vm.prank(beneficiary);
            if (expectedReleasable > 0) {
                console.log(unicode"执行释放操作");
                vesting.release();
                console.log(unicode"释放完成，当前已释放总额: %d", vesting.released());
            } else {
                console.log(unicode"无可释放代币，应触发 revert");
                vm.expectRevert();
                vesting.release();
            }

            // 时间前进一个月
            vm.warp(block.timestamp + 30 days);
            console.log(unicode"时间前进一个月，当前时间戳: %d", block.timestamp);
        }

        // 24次释放后，受益人应拥有几乎全部代币（可能存在小的舍入误差）
        // 验证：受益人余额 + 合约余额 = 总分配量
        uint256 beneficiaryBal = token.balanceOf(beneficiary);
        uint256 vestingBal = token.balanceOf(address(vesting));
        console.log(unicode"释放完成，受益人余额: %d, 合约余额: %d, 总和: %d", beneficiaryBal, vestingBal, beneficiaryBal + vestingBal);
        console.log(unicode"总分配量: %d", total);
        assertEq(beneficiaryBal + vestingBal, total);
        console.log(unicode"每月释放测试通过");
    }

    // 测试 vesting 期结束后一次性释放所有代币
    function testFullReleaseAfterEnd() public {
        console.log(unicode"=== 测试 vesting 期结束后释放 ===");
        uint256 total = token.balanceOf(address(vesting));
        console.log(unicode"总金额: %d", total);
        // 时间前进到 vesting 期结束后（12 + 24 个月）
        console.log(unicode"时间前进到 vesting 期结束后");
        vm.warp(block.timestamp + 36 * 30 days + 10);
        console.log(unicode"当前时间戳: %d, 结束时间戳: %d", block.timestamp, vesting.endTimestamp());
        uint256 expectReleasable = total; // 所有代币都应可释放
        uint256 actualReleasable = vesting.releasableAmount();
        console.log(unicode"unicode预期可释放: %d, 实际可释放: %d", expectReleasable, actualReleasable);
        assertEq(actualReleasable, expectReleasable);

        console.log(unicode"执行释放操作");
        vm.prank(beneficiary);
        vesting.release();
        // 检查受益人是否收到所有代币
        uint256 beneficiaryBalance = token.balanceOf(beneficiary);
        uint256 contractBalance = token.balanceOf(address(vesting));
        console.log(unicode"释放后受益人余额: %d, 合约余额: %d", beneficiaryBalance, contractBalance);
        assertEq(beneficiaryBalance, expectReleasable);
        // 检查合约余额是否为0
        assertEq(contractBalance, 0);
        console.log(unicode"vesting 期结束后释放测试通过");
    }
}