# 部署指南

## 快速开始

### 1. 配置部署参数
```bash
# 编辑配置文件
cp config/deploy.example.env config/deploy.env
# 然后编辑 config/deploy.env 文件，填入你的实际配置
```

### 2. 一键部署
```bash
# 确保有执行权限
chmod +x scripts/deploy-testnet.sh

# 部署到Sepolia测试网
./scripts/deploy-testnet.sh sepolia
```

### 3. 检查结果
部署完成后，查看 `deployment.env` 文件获取合约地址。

---

## 详细部署步骤

### 1. 配置文件

部署脚本现在优先从 `config/deploy.env` 文件读取配置，你可以从示例文件开始：

```bash
# 合约配置
NFT_NAME="Ken"
NFT_SYMBOL="Wu"
BASE_URI="https://myapi.com/9527/"

# 升级配置
UPGRADE_TO_V2="true"

# 网络配置
ETH_RPC_URL="https://sepolia.infura.io/v3/your_infura_key"
ETHERSCAN_API_KEY="your_etherscan_api_key"

# 部署者配置
DEPLOYER_PRIVATE_KEY="your_private_key_here"
```

你可以编辑 `config/deploy.env` 文件来修改配置。如果配置文件不存在，脚本会回退到使用环境变量。

### 2. 环境变量配置 (备用方案)

如果不使用配置文件，可以创建 `.env` 文件并配置以下参数：

```bash
# 私钥 (用于部署)
PRIVATE_KEY=your_private_key_here

# RPC URL (测试网)
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your_infura_key

# 区块链浏览器API密钥 (用于验证)
ETHERSCAN_API_KEY=your_etherscan_api_key

# NFT合约配置
NFT_NAME=UpgradableNFT
NFT_SYMBOL=UNFT
BASE_URI=https://api.example.com/metadata/
OWNER=0x1234567890123456789012345678901234567890

# 是否升级到V2
UPGRADE_TO_V2=false
```

### 3. 部署到测试网

#### 使用配置文件部署 (推荐)
```bash
# 确保config/deploy.env文件已正确配置，然后直接运行
forge script script/Deploy.s.sol --rpc-url $ETH_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --verify

# 或者使用简化的部署脚本
./scripts/deploy-testnet.sh sepolia
```

#### 使用环境变量部署
```bash
# 部署V1合约
forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify

# 部署并升级到V2
UPGRADE_TO_V2=true forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```

### 4. 手动验证合约

如果自动验证失败，可以使用部署脚本输出的验证命令：

```bash
# 验证V1实现合约
forge verify-contract <V1_IMPLEMENTATION_ADDRESS> src/UpgradableNFT.sol:UpgradableNFT --chain-id 11155111 --etherscan-api-key $ETHERSCAN_API_KEY

# 验证V2实现合约 (如果升级了)
forge verify-contract <V2_IMPLEMENTATION_ADDRESS> src/UpgradableNFTV2.sol:UpgradableNFTV2 --chain-id 11155111 --etherscan-api-key $ETHERSCAN_API_KEY

# 验证代理合约
forge verify-contract <PROXY_ADDRESS> lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy --chain-id 11155111 --etherscan-api-key $ETHERSCAN_API_KEY
```

### 5. 其他测试网

#### Goerli测试网
```bash
GOERLI_RPC_URL=https://goerli.infura.io/v3/your_infura_key
forge script script/Deploy.s.sol --rpc-url $GOERLI_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```

#### Mumbai测试网 (Polygon)
```bash
MUMBAI_RPC_URL=https://polygon-mumbai.infura.io/v3/your_infura_key
forge script script/Deploy.s.sol --rpc-url $MUMBAI_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```

### 6. 部署后检查

部署完成后，检查 `deployment.env` 文件中的合约地址，并在区块链浏览器中验证：

- [Sepolia Etherscan](https://sepolia.etherscan.io/)
- [Goerli Etherscan](https://goerli.etherscan.io/)
- [Mumbai PolygonScan](https://mumbai.polygonscan.com/)

### 7. 注意事项

1. 确保测试网账户有足够的ETH用于部署
2. 验证需要一些时间，请耐心等待
3. 代理合约的源码验证可能需要额外的构造函数参数
4. 建议先在测试网测试所有功能再部署到主网
