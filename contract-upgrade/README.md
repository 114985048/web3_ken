# 可升级 ERC721 NFT 合约
V1 实现合约: 0x5b73C5498c1E3b4dbA84de0F1833c4a029d90519
V2 实现合约: 0x34A1D3fff3958843C43aD80F30b94c510645C316
代理合约: 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496

一个基于 OpenZeppelin 的可升级 ERC721 NFT 合约项目，支持 UUPS 升级模式和离线签名上架功能。

## 项目特性

### V1 版本功能
- ✅ 基于 OpenZeppelin 的可升级合约框架
- ✅ UUPS (Universal Upgradeable Proxy Standard) 升级模式
- ✅ NFT 铸造功能
- ✅ 基础 URI 设置
- ✅ 所有权管理

### V2 版本功能
- ✅ 继承 V1 的所有功能
- ✅ 离线签名上架 NFT
- ✅ EIP712 标准签名验证
- ✅ NFT 购买功能
- ✅ 取消上架功能
- ✅ 重放攻击防护 (nonce 机制)

## 合约架构

```
代理合约 (ERC1967Proxy)
    ↓
V1 实现合约 (UpgradableNFT)
    ↓ (升级)
V2 实现合约 (UpgradableNFTV2)
```

## 部署的合约地址

### 主网部署
*待部署*

### 测试网部署

#### Sepolia 测试网
- **代理合约**: `0x...` *(待部署)*
- **V1 实现合约**: `0x...` *(待部署)*
- **V2 实现合约**: `0x...` *(待部署)*

#### Goerli 测试网
- **代理合约**: `0x...` *(待部署)*
- **V1 实现合约**: `0x...` *(待部署)*
- **V2 实现合约**: `0x...` *(待部署)*

#### Polygon Mumbai 测试网
- **代理合约**: `0x...` *(待部署)*
- **V1 实现合约**: `0x...` *(待部署)*
- **V2 实现合约**: `0x...` *(待部署)*

## 快速开始

### 环境要求

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js 16+
- Git

### 安装依赖

```bash
# 克隆项目
git clone <repository-url>
cd contract-upgrade

# 安装 Foundry 依赖
forge install

# 安装 Node.js 依赖
npm install
```

### 编译合约

```bash
forge build
```

### 运行测试

```bash
# 运行所有测试
forge test

# 运行测试并显示详细日志
forge test -vv

# 运行特定测试
forge test --match-test testV1BasicFunctionality
```

### 部署合约

#### 使用部署脚本

```bash
# 部署到本地 Anvil 网络
./scripts/deploy.sh --network anvil

# 部署到 Sepolia 测试网
./scripts/deploy.sh --network sepolia --verify

# 部署并立即升级到 V2
./scripts/deploy.sh --network sepolia --upgrade-to-v2 --verify

# 自定义合约参数
./scripts/deploy.sh \
  --network sepolia \
  --name "MyNFT" \
  --symbol "MNFT" \
  --base-uri "https://api.mynft.com/metadata/" \
  --verify
```

#### 手动部署

```bash
# 设置环境变量
export NFT_NAME="UpgradableNFT"
export NFT_SYMBOL="UNFT"
export BASE_URI="https://api.example.com/metadata/"
export OWNER="0xYourAddress"

# 部署到 Sepolia
forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --verify
```

### 验证合约

```bash
# 运行验证脚本
forge script script/Verify.s.sol --rpc-url sepolia

# 手动验证
forge verify-contract <CONTRACT_ADDRESS> src/UpgradableNFT.sol:UpgradableNFT --etherscan-api-key <API_KEY>
```

## 使用指南

### V1 基本功能

```solidity
// 铸造 NFT
uint256 tokenId = nft.mintWithURI(user, "token1.json");

// 设置基础 URI
nft.setBaseURI("https://api.example.com/metadata/");

// 获取 NFT 信息
string memory name = nft.name();
string memory symbol = nft.symbol();
string memory tokenURI = nft.tokenURI(tokenId);
```

### V2 离线签名上架

```solidity
// 1. 用户签名上架信息
bytes32 structHash = keccak256(abi.encode(
    keccak256("Listing(uint256 tokenId,uint256 price,uint256 nonce)"),
    tokenId,
    price,
    nonce
));

// 2. 使用 EIP712 签名
bytes32 hash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
bytes memory signature = sign(hash);

// 3. 调用上架函数
nft.listNFTWithSignature(tokenId, price, nonce, signature);
```

### 购买 NFT

```solidity
// 购买 NFT
nft.buyNFT{value: price}(tokenId);
```

### 取消上架

```solidity
// 取消上架
nft.unlistNFT(tokenId);
```

## 测试覆盖

项目包含完整的测试套件，覆盖以下场景：

- ✅ V1 基本功能测试
- ✅ V2 离线签名上架测试
- ✅ V2 购买功能测试
- ✅ 合约升级过程测试
- ✅ 错误情况测试
- ✅ 状态一致性验证

### 运行测试报告

```bash
# 生成测试报告
forge test --gas-report

# 运行特定测试并显示详细日志
forge test --match-test testContractUpgrade -vvvv
```

## 安全特性

- **UUPS 升级模式**: 确保升级逻辑在实现合约中，提高安全性
- **EIP712 签名**: 标准化的离线签名验证
- **重放攻击防护**: 使用 nonce 机制防止重放攻击
- **所有权验证**: 确保只有 NFT 所有者可以上架
- **价格验证**: 防止无效价格上架

## 开发工具

### 签名生成工具

项目包含 JavaScript 工具用于生成和验证 EIP712 签名：

```javascript
const { generateListingSignature, verifySignature } = require('./script/signature-helper.js');

// 生成签名
const signature = generateListingSignature(
    tokenId,
    price,
    nonce,
    contractAddress,
    chainId
);

// 验证签名
const recoveredAddress = verifySignature(
    tokenId,
    price,
    nonce,
    signature,
    contractAddress,
    chainId
);
```

## 网络配置

### 环境变量

```bash
# RPC URLs
export ETH_RPC_URL="https://sepolia.infura.io/v3/YOUR_PROJECT_ID"
export POLYGON_RPC_URL="https://polygon-mumbai.infura.io/v3/YOUR_PROJECT_ID"

# API Keys
export ETHERSCAN_API_KEY="YOUR_ETHERSCAN_API_KEY"
export POLYGONSCAN_API_KEY="YOUR_POLYGONSCAN_API_KEY"

# 部署配置
export NFT_NAME="UpgradableNFT"
export NFT_SYMBOL="UNFT"
export BASE_URI="https://api.example.com/metadata/"
export OWNER="0xYourAddress"
```

## 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 联系方式

- 项目链接: [https://github.com/yourusername/contract-upgrade](https://github.com/yourusername/contract-upgrade)
- 问题反馈: [Issues](https://github.com/yourusername/contract-upgrade/issues)

## 致谢

- [OpenZeppelin](https://openzeppelin.com/) - 可升级合约框架
- [Foundry](https://book.getfoundry.sh/) - 开发工具链
- [EIP-712](https://eips.ethereum.org/EIPS/eip-712) - 结构化数据签名标准