import 'dotenv/config'
import { createPublicClient, createWalletClient, custom, http } from 'viem'
import { sepolia } from 'viem/chains'
import { privateKeyToAccount } from 'viem/accounts'
//

// RPC Provider
const publicClient = createPublicClient({
  chain: sepolia,
  transport: http(process.env.SEPOLIA_RPC_URL!),
})

// 卖家钱包
const sellerAccount = privateKeyToAccount(process.env.SELLER_PK! as `0x${string}`)
const sellerClient = createWalletClient({
  account: sellerAccount,
  chain: sepolia,
  transport: http(process.env.SEPOLIA_RPC_URL!)
})

// 买家钱包
const buyerAccount = privateKeyToAccount(process.env.BUYER_PK! as `0x${string}`)
const buyerClient = createWalletClient({
  account: buyerAccount,
  chain: sepolia,
  transport: http(process.env.SEPOLIA_RPC_URL!)
})

// 合约 ABI & 地址
const nftAbi = [
  'function listNFTWithSignature(uint256 tokenId,uint256 price,uint256 nonce,bytes signature) external',
  'function buyNFT(uint256 tokenId) external payable',
  'function getUserNonce(address user) view returns (uint256)'
]
const proxyAddress = process.env.PROXY_ADDRESS!

// ---------------- 挂单 ----------------
async function listNFT(tokenId: number, price: bigint) {
  // 获取 nonce
  const nonce = Number(await publicClient.readContract({
    address: proxyAddress as `0x${string}`,
    abi: nftAbi,
    functionName: 'getUserNonce',
    args: [sellerAccount.address]
  })) + 1

  // EIP712 Domain
  const domain = {
    name: 'UpgradableNFT',
    version: '2',
    chainId: 11155111,
    verifyingContract: proxyAddress as `0x${string}`
  }

  // 类型
  const types = {
    Listing: [
      { name: 'tokenId', type: 'uint256' },
      { name: 'price', type: 'uint256' },
      { name: 'nonce', type: 'uint256' }
    ]
  }

  // 数据
  const value = {
    tokenId,
    price,
    nonce
  }

  // 签名
  const signature = await sellerClient.signTypedData({
    domain,
    types,
    primaryType: 'Listing',
    message: value
  })
  

  console.log('Signature:', signature)

  // 调用挂单
  const txHash = await sellerClient.writeContract({
    address: proxyAddress as `0x${string}`,
    abi: nftAbi,
    functionName: 'listNFTWithSignature',
    args: [tokenId, price, nonce, signature],
  })
  console.log('NFT listed, tx:', txHash)
}

// ---------------- 购买 ----------------
async function buyNFT(tokenId: number, price: bigint) {
  const txHash = await buyerClient.writeContract({
    address: proxyAddress as `0x${string}`,
    abi: nftAbi,
    functionName: 'buyNFT',
    args: [tokenId],
    value: price
  })
  console.log('NFT bought, tx:', txHash)
}

// ---------------- 主流程 ----------------
async function main() {
  const tokenId = 1
  const price = 10n ** 16n // 0.01 ETH in wei

  await listNFT(tokenId, price)
  await buyNFT(tokenId, price)
}

main().catch(console.error)
