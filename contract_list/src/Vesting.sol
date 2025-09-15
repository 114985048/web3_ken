// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title 线性解锁 Vesting 合约
/// @notice 受益人有 12 个月 cliff，之后 24 个月每月线性释放 1/24。
contract Vesting {
    IERC20 public immutable token;        // 被锁定的 ERC20 代币
    address public immutable beneficiary; // 受益人
    uint256 public immutable start;       // 部署时的时间戳
    uint256 public constant CLIFF_MONTHS = 12;   // cliff 12 个月
    uint256 public constant RELEASE_MONTHS = 24; // 线性释放 24 个月
    uint256 public constant SECONDS_PER_MONTH = 30 days; // 定义“月”为 30 天

    uint256 public immutable cliffTimestamp; // cliff 结束时间戳
    uint256 public immutable endTimestamp;   // vesting 结束时间戳
    uint256 public released;                 // 已释放的代币数量

    event Released(address indexed to, uint256 amount);

    constructor(address _token, address _beneficiary) {
        require(_token != address(0), "zero token");
        require(_beneficiary != address(0), "zero beneficiary");
        token = IERC20(_token);
        beneficiary = _beneficiary;

        start = block.timestamp;
        cliffTimestamp = start + (CLIFF_MONTHS * SECONDS_PER_MONTH);
        endTimestamp = cliffTimestamp + (RELEASE_MONTHS * SECONDS_PER_MONTH);
    }

    /// @notice 总分配的数量 = 合约余额 + 已释放数量
    function totalAllocated() public view returns (uint256) {
        return token.balanceOf(address(this)) + released;
    }

    /// @notice 计算当前已解锁的总量（包含已释放的部分）
    function vestedAmount() public view returns (uint256) {
        uint256 total = totalAllocated();

        if (block.timestamp < cliffTimestamp) {
            // cliff 期内不解锁
            return 0;
        } else if (block.timestamp >= endTimestamp) {
            // vesting 结束，全额解锁
            return total;
        } else {
            // cliff 结束后，按月解锁
            uint256 secondsSinceCliff = block.timestamp - cliffTimestamp;
            uint256 monthsElapsed = secondsSinceCliff / SECONDS_PER_MONTH; // 整月数
            uint256 monthShare = total / RELEASE_MONTHS;
            uint256 vested = monthShare * (monthsElapsed + 1); // 第 13 个月开始释放
            if (vested > total) vested = total;
            return vested;
        }
    }

    /// @notice 当前可释放（未释放部分）
    function releasableAmount() public view returns (uint256) {
        uint256 vested = vestedAmount();
        if (vested <= released) return 0;
        return vested - released;
    }

    /// @notice 释放代币给受益人
    function release() external {
        uint256 amount = releasableAmount();
        require(amount > 0, "no tokens to release");
        released += amount;
        require(token.transfer(beneficiary, amount), "transfer failed");
        emit Released(beneficiary, amount);
    }
}
