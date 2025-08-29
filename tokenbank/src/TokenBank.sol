// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol"; 
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; 
 
contract TokenBank is ReentrancyGuard {
    IERC20 public immutable token;
    mapping(address => uint256) public balances;
    
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event PermitDeposited(address indexed user, uint256 amount);
 
    constructor(address _token) {
        token = IERC20(_token);
    }
 
    // 传统存款方式
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        
        bool success = token.transferFrom(msg.sender,  address(this), amount);
        require(success, "Transfer failed");
        
        balances[msg.sender] += amount;
        emit Deposited(msg.sender,  amount);
    }
 
    // 支持 Permit 的存款方式 
    function permitDeposit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        
        // 使用 permit 授权
        IERC20Permit(address(token)).permit(
            msg.sender, 
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        
        // 转移代币 
        bool success = token.transferFrom(msg.sender,  address(this), amount);
        require(success, "Transfer failed");
        
        balances[msg.sender] += amount;
        emit PermitDeposited(msg.sender,  amount);
    }
 
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        bool success = token.transfer(msg.sender,  amount);
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender,  amount);
    }
 
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}