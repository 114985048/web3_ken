# Kentoken 前端应用

这是一个基于 React 的代币转账前端应用，支持与以太坊智能合约交互。

## 功能特性

- 🔗 钱包连接 (MetaMask)
- 💸 代币转账
- 📊 转账记录展示
- 💰 余额显示
- 📱 响应式设计

## 安装和运行

### 1. 安装依赖

```bash
npm install
```

### 2. 配置合约地址

在 `src/App.jsx` 中修改以下配置：

```javascript
// 合约地址 - 需要根据实际部署的地址进行修改
const CONTRACT_ADDRESS = "你的合约地址";

// 合约 ABI - 如果需要，可以添加更多函数
const CONTRACT_ABI = [
  "function transfer(address to, uint256 amount) returns (bool)",
  "function balanceOf(address account) view returns (uint256)",
  "function decimals() view returns (uint8)",
  "function symbol() view returns (string)"
];
```

### 3. 启动监听 跟 开发服务器

```bash
cd kentoken/frontend/listen & node indexAllTransfersToDB.js 
npm run dev
```

应用将在 http://localhost:3000 启动。

### 4. 构建生产版本

```bash
npm run build
```

## 使用说明

1. **连接钱包**: 点击"连接钱包"按钮，授权 MetaMask 连接
2. **查看余额**: 连接成功后会自动显示当前账户的代币余额
3. **转账**: 在转账表单中输入接收地址和金额，点击"确认转账"
4. **查看记录**: 转账记录会自动从后端 API 获取并显示

## API 接口

应用使用以下后端 API：

- `GET http://localhost:8080/api/transfers/${userAddress}` - 获取用户转账记录

返回数据格式：
```json
[
  {
    "id": 2,
    "fromAddress": "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
    "toAddress": "0x70997970c51812dc3a010c7d01b50e0d17dc79c8",
    "amount": 11000000000000000000,
    "txHash": "0x0732e4528b21cf162ccac41014355f2e2c79defcdca76b2caa14340a45f4149e",
    "blockNumber": 2,
    "timestamp": null
  }
]
```

## 技术栈

- React 18
- Ethers.js 6
- Axios
- Vite
- CSS3

## 注意事项

1. 确保 MetaMask 已安装并连接到正确的网络
2. 确保后端 API 服务正在运行
3. 确保合约已正确部署到目标网络
4. 转账前请确认接收地址的正确性
