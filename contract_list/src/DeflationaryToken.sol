// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// 实现一个通缩的 Token （ERC20）， 用来理解 rebase 型 Token 的实现原理：

// 起始发行量为 1 亿，税后每过一年在上一年的发行量基础上下降 1%
// rebase 方法进行通缩
// balanceOf() 可反应通缩后的用户的正确余额。
// 需要测试 rebase 后，正确显示用户的余额
contract DeflationaryToken is ERC20 {
    // 总供应量（经过rebase调整后的实际供应量）
    uint256 private _totalSupply;
    // 上次rebase的时间戳
    uint256 private _lastRebaseTime;
    // rebase执行次数
    uint256 private _rebaseCount;
    // 初始供应量（1亿）
    uint256 private _initialSupply;
    // 缩放后的总供应量（用于内部计算）
    uint256 private _scaledTotalSupply;
    // 缩放因子基数（避免浮点数计算）
    uint256 private constant _SCALE_FACTOR = 1e18;
    
    // 通缩率：每年1%（即保留99%）
    uint256 private constant _DEFLATION_RATE = 99;
    // 通缩率分母
    uint256 private constant _RATE_DENOMINATOR = 100;
    // 一年的秒数（365天）
    uint256 private constant _SECONDS_IN_YEAR = 365 days;

    constructor() ERC20("Deflationary Token", "DFT") {
        // 初始化1亿个代币
        _initialSupply = 100_000_000 * 10 ** decimals();
        _totalSupply = _initialSupply;
        // 缩放后的总供应量 = 实际供应量 * 缩放因子
        _scaledTotalSupply = _initialSupply * _SCALE_FACTOR;
        // 记录部署时间为第一次rebase时间
        _lastRebaseTime = block.timestamp;
        _rebaseCount = 0;
        
        // 将初始供应量全部铸造给合约部署者
        _mint(msg.sender, _initialSupply);
    }

    // 重写totalSupply函数，返回经过rebase调整后的实际总供应量
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    // 重写balanceOf函数，返回经过缩放因子调整后的用户余额
    function balanceOf(address account) public view override returns (uint256) {
        // 获取基础余额（未缩放）
        uint256 scaledBalance = super.balanceOf(account);
        // 计算实际余额 = 缩放余额 / 当前缩放因子
        return scaledBalance * _SCALE_FACTOR / _getScaleFactor();
    }

    // Rebase函数：执行通缩调整（每年只能调用一次）
    function rebase() public {
        // 检查是否已经过了一年
        require(block.timestamp >= _lastRebaseTime + _SECONDS_IN_YEAR, "Rebase can only be called once per year");
        
        // 计算新的缩放因子（乘以99%）
        //uint256 newScaleFactor = _getScaleFactor() * _DEFLATION_RATE / _RATE_DENOMINATOR;
        
        // 更新总供应量（减少1%）
        _totalSupply = _totalSupply * _DEFLATION_RATE / _RATE_DENOMINATOR;
        
        // 更新缩放后的总供应量
        _scaledTotalSupply = _totalSupply * _SCALE_FACTOR;
        
        // 更新最后一次rebase时间和计数
        _lastRebaseTime = block.timestamp;
        _rebaseCount++;
        
        // 触发Rebase事件
        emit Rebase(_rebaseCount, _totalSupply);
    }

    // 内部函数：获取当前缩放因子
    function _getScaleFactor() internal view returns (uint256) {
        // 如果还没有执行过rebase，返回基础缩放因子
        if (_rebaseCount == 0) {
            return _SCALE_FACTOR;
        }
        
        // 计算缩放因子 = SCALE_FACTOR * (DEFLATION_RATE / RATE_DENOMINATOR) ^ rebaseCount
        uint256 scaleFactor = _SCALE_FACTOR;
        for (uint256 i = 0; i < _rebaseCount; i++) {
            scaleFactor = scaleFactor * _DEFLATION_RATE / _RATE_DENOMINATOR;
        }
        return scaleFactor;
    }

    // 查看函数：获取rebase相关信息
    function getRebaseInfo() public view returns (
        uint256 lastRebaseTime,    // 上次rebase时间
        uint256 rebaseCount,       // rebase执行次数
        uint256 currentScaleFactor, // 当前缩放因子
        uint256 nextRebaseTime     // 下次可执行rebase的时间
    ) {
        return (
            _lastRebaseTime,
            _rebaseCount,
            _getScaleFactor(),
            _lastRebaseTime + _SECONDS_IN_YEAR
        );
    }

    // Rebase事件：记录rebase执行次数和新的总供应量
    event Rebase(uint256 indexed rebaseCount, uint256 totalSupply);
}