# 部署配置说明

## 配置文件

### `deploy.env`
部署配置文件，包含所有部署相关的配置项。

## 使用方法

1. **编辑配置文件**：
   修改 `config/deploy.env` 文件，填入你的实际配置：
   ```bash
   # 合约配置
   NFT_NAME="MyUpgradableNFT"
   NFT_SYMBOL="MUNFT"
   BASE_URI="https://myapi.com/metadata/"
   
   # 升级配置
   UPGRADE_TO_V2="true"
   
   # 网络配置
   ETH_RPC_URL="https://sepolia.infura.io/v3/YOUR_PROJECT_ID"
   ETHERSCAN_API_KEY="YOUR_ETHERSCAN_API_KEY"
   
   # 部署者配置
   DEPLOYER_PRIVATE_KEY="YOUR_PRIVATE_KEY"
   ```

2. **运行部署脚本**：
   ```bash
   ./scripts/deploy.sh
   ```

## 配置优先级

部署脚本会按以下优先级加载配置：

1. `config/deploy.env` 配置文件
2. 环境变量
3. 脚本内置默认值

## 安全注意事项

- **不要将 `deploy.env` 文件提交到版本控制系统**
- 私钥等敏感信息应该通过环境变量或安全的密钥管理系统设置
- 建议将 `deploy.env` 添加到 `.gitignore` 文件中

## 配置项说明

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `NFT_NAME` | NFT 合约名称 | "UpgradableNFT" |
| `NFT_SYMBOL` | NFT 合约符号 | "UNFT" |
| `BASE_URI` | 元数据基础 URI | "https://api.example.com/metadata/" |
| `UPGRADE_TO_V2` | 是否升级到 V2 | "false" |
| `ETH_RPC_URL` | 以太坊 RPC 节点 URL | 必需 |
| `ETHERSCAN_API_KEY` | Etherscan API 密钥 | 可选 |
| `DEPLOYER_PRIVATE_KEY` | 部署者私钥 | 可选 |
