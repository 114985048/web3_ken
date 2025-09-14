// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

contract Bank is AutomationCompatibleInterface {
     mapping(address => uint256) public balances;
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event AutoTransfer(address indexed owner, uint256 amount);

    address public owner;
    uint256 public threshold; // 触发阈值（单位 wei）

    constructor(uint256 _threshold) {
        owner = msg.sender;
        threshold = _threshold;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    function withdraw(uint256 amount) public {
        require(amount > 0, "Withdraw amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Not sufficient funds");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    // ------------ Chainlink Automation ------------

    /// @notice checkUpkeep 会被 Keeper 节点调用 (off-chain)，用于检测条件是否满足
    function checkUpkeep(
        bytes calldata /* checkData */
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = address(this).balance >= threshold;
        performData = "";
    }

    /// @notice performUpkeep 会被自动调用 (on-chain)，当条件满足时执行
    function performUpkeep(bytes calldata /* performData */) external override {
        if (address(this).balance >= threshold) {
            uint256 amount = address(this).balance / 2; // 一半存款
            payable(owner).transfer(amount);
            emit AutoTransfer(owner, amount);
        }
    }

    // fallback: 直接转账也会当作 deposit
    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
}
