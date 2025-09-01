
const { ethers } = require("ethers");
const mysql = require("mysql2/promise"); // 使用 promise 版本
require("dotenv").config();

// MyToken ABI
const tokenAbi = [
  "event Transfer(address indexed from, address indexed to, uint256 value)",
  "function decimals() view returns (uint8)"
];

// 配置
const RPC_URL = process.env.RPC_URL || "http://localhost:8545";
const CONTRACT_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3"; // 替换为实际地址
const DB_CONFIG = {
  host: "169.254.75.84",
  user: "root",
  password: "root", // 替换为你的 MySQL 密码
  database: "token_transfers",
  port: 3306,  // 明确指定端口
  connectTimeout: 60000,
  charset: 'utf8mb4'
};

async function indexAllTransfersToDB() {
  try {
    console.log("正在尝试连接数据库...");
    console.log("数据库配置:", JSON.stringify(DB_CONFIG, null, 2));
    console.log("合约地址:", CONTRACT_ADDRESS);
    console.log("RPC URL:", RPC_URL);
    
    // 连接数据库
    const pool = mysql.createPool(DB_CONFIG);
    
    // 测试数据库连接
    const connection = await pool.getConnection();
    console.log("数据库连接成功");
    connection.release();

    // 连接区块链
    const provider = new ethers.JsonRpcProvider(RPC_URL);
    const contract = new ethers.Contract(CONTRACT_ADDRESS, tokenAbi, provider);
    const decimals = await contract.decimals();

    // 查询历史记录并插入（避免重复插入，通过 tx_hash 检查）
    const filter = contract.filters.Transfer();
    const logs = await contract.queryFilter(filter);
    console.log(`找到 ${logs.length} 条历史转账记录`);
    
    for (const log of logs) {
      try {
        console.log('处理历史记录:', log);
        console.log('log.args:', log.args);
        
        const from = log.args.from.toLowerCase();
        const to = log.args.to.toLowerCase();
        const value = log.args.value.toString(); // 使用字符串存储大数
        const txHash = log.transactionHash.toLowerCase();
        const blockNumber = log.blockNumber;

        console.log('解析的历史记录数据:', { from, to, value, txHash, blockNumber });

        // 检查是否已存在
        const [rows] = await pool.execute("SELECT id FROM transfers WHERE tx_hash = ?", [txHash]);
        if (rows.length === 0) {
          await pool.execute(
            "INSERT INTO transfers (from_address, to_address, amount, tx_hash, block_number) VALUES (?, ?, ?, ?, ?)",
            [from, to, value, txHash, blockNumber]
          );
          console.log(`插入历史记录: ${from} -> ${to}, 数量: ${ethers.formatUnits(value, decimals)} MTK`);
        } else {
          console.log(`历史记录已存在，跳过: ${txHash}`);
        }
      } catch (error) {
        console.error('处理历史记录时出错:', error);
        console.error('日志数据:', log);
      }
    }

    // 实时监听并插入
    contract.on("Transfer", async (...args) => {
      try {
        console.log('收到 Transfer 事件，参数:', args);
        
        // 在 ethers.js v6 中，事件参数的结构可能不同
        let from, to, value, event;
        
        if (args.length === 4) {
          // 传统格式: (from, to, value, event)
          [from, to, value, event] = args;
        } else if (args.length === 1 && args[0].args) {
          // 新格式: 事件对象包含 args
          event = args[0];
          from = event.args.from;
          to = event.args.to;
          value = event.args.value;
        } else {
          console.error('未知的事件参数格式:', args);
          return;
        }
        
        //console.log('解析后的事件数据:', { from, to, value });
        
        const formattedValue = ethers.formatUnits(value, decimals);
        
        // 在 ethers.js v6 中，需要从 event.log 获取交易信息
        const txHash = event.log?.transactionHash || event.transactionHash;
        const blockNumber = event.log?.blockNumber || event.blockNumber;
        
        if (!txHash) {
          console.error('无法获取交易哈希:', event);
          return;
        }
        
        const txHashLower = txHash.toLowerCase();
        const fromLower = from.toLowerCase();
        const toLower = to.toLowerCase();
        const valueStr = value.toString();

        // 检查是否存在
        const [rows] = await pool.execute("SELECT id FROM transfers WHERE tx_hash = ?", [txHashLower]);
        if (rows.length === 0) {
          await pool.execute(
            "INSERT INTO transfers (from_address, to_address, amount, tx_hash, block_number) VALUES (?, ?, ?, ?, ?)",
            [fromLower, toLower, valueStr, txHashLower, blockNumber]
          );
          console.log(`插入新记录: ${fromLower} -> ${toLower}, 数量: ${formattedValue} MTK`);
        } else {
          console.log(`记录已存在，跳过: ${txHashLower}`);
        }
      } catch (error) {
        console.error('处理 Transfer 事件时出错:', error);
        console.error('事件数据:', args);
      }
    });

    console.log(`正在持续监听并插入数据库...`);
    console.log(`监听合约地址: ${CONTRACT_ADDRESS}`);
    console.log(`代币精度: ${decimals}`);

    // 添加错误处理
    contract.on("error", (error) => {
      console.error("合约监听错误:", error);
    });

    process.on('SIGINT', async () => {
      console.log("收到停止信号，正在清理...");
      contract.removeAllListeners();
      await pool.end();
      console.log("停止监听并关闭数据库连接...");
      process.exit(0);
    });

    process.on('unhandledRejection', (reason, promise) => {
      console.error('未处理的 Promise 拒绝:', reason);
    });

    process.on('uncaughtException', (error) => {
      console.error('未捕获的异常:', error);
      process.exit(1);
    });

  } catch (error) {
    console.error("错误:", error.message);
    process.exit(1);
  }
}

indexAllTransfersToDB();