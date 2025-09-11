// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    // 存储每个地址存款余额的映射
    mapping(address => uint256) public balances;

    // 链表节点的结构体
    struct UserNode {
        uint256 amount; // 存款金额
        address prev;   // 前一个节点的地址
        address next;   // 下一个节点的地址
    }

    // 存储前 10 名用户链表的映射
    mapping(address => UserNode) public topUsers;

    // 链表头部（最高金额用户）
    address public head;
    // 链表尾部（最低金额用户）
    address public tail;

    // 当前前 10 名用户的数量（最多 10 个）
    uint256 public topCount;

    // 接收直接 ETH 转账的函数
    receive() external payable {
        require(msg.value > 0, "The deposit amount must be greater than 0");
        balances[msg.sender] += msg.value; // 更新存款余额
        updateTop10(msg.sender); // 更新前 10 名列表
    }

    // 内部函数：更新前 10 名用户列表
    function updateTop10(address user) internal {
        uint256 newAmount = balances[user]; // 获取用户的存款金额

        // 检查用户是否已在链表中
        bool inList = topUsers[user].prev != address(0) ||
                      topUsers[user].next != address(0) ||
                      head == user;

        if (inList) {
            // 如果用户在链表中，先移除其当前位置
            remove(user);
        }

        // 如果新金额为 0，直接返回（存款不会为 0）
        if (newAmount == 0) {
            return;
        }

        if (topCount < 10) {
            // 如果列表未满，直接插入
            insert(user, newAmount);
        } else {
            // 如果列表已满，检查新金额是否大于链表尾部（最小值）
            if (newAmount > topUsers[tail].amount) {
                // 移除尾部用户并插入新用户
                remove(tail);
                insert(user, newAmount);
            }
        }
    }

    // 内部函数：从链表中移除用户
    function remove(address user) internal {
        UserNode storage node = topUsers[user];

        if (node.prev != address(0)) {
            // 更新前一个节点的 next 指针
            topUsers[node.prev].next = node.next;
        } else {
            // 如果是头部，更新 head
            head = node.next;
        }

        if (node.next != address(0)) {
            // 更新下一个节点的 prev 指针
            topUsers[node.next].prev = node.prev;
        } else {
            // 如果是尾部，更新 tail
            tail = node.prev;
        }

        // 删除用户节点
        delete topUsers[user];
        topCount--;
    }

    // 内部函数：将用户插入到按金额降序排列的链表中
    function insert(address user, uint256 amount) internal {
        address prev = address(0);
        address curr = head;

        // 找到插入位置（curr.amount < amount 的第一个节点）
        while (curr != address(0) && topUsers[curr].amount >= amount) {
            prev = curr;
            curr = topUsers[curr].next;
        }

        // 插入新节点
        topUsers[user] = UserNode(amount, prev, curr);

        if (prev != address(0)) {
            // 更新前一个节点的 next 指针
            topUsers[prev].next = user;
        } else {
            // 如果插入头部，更新 head
            head = user;
        }

        if (curr != address(0)) {
            // 更新下一个节点的 prev 指针
            topUsers[curr].prev = user;
        } else {
            // 如果插入尾部，更新 tail
            tail = user;
        }

        topCount++;
    }

    // 查看函数：获取前 10 名用户及其存款金额
    function getTop10() public view returns (address[] memory users, uint256[] memory amounts) {
        users = new address[](topCount);
        amounts = new uint256[](topCount);

        address curr = head;
        uint256 i = 0;

        // 遍历链表，收集用户地址和金额
        while (curr != address(0)) {
            users[i] = curr;
            amounts[i] = topUsers[curr].amount;
            curr = topUsers[curr].next;
            i++;
        }
    }
}