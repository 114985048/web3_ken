// 使用: NODE_OPTIONS=--experimental-fetch node readLocksViem.js
import { createPublicClient, http, keccak256, toHex, getAddress, hexToBigInt } from 'viem';

// 必需：设置 RPC 与合约地址
const RPC_URL = process.env.RPC_URL || process.env.SEPOLIA_RPC_URL; // 或你的链 RPC
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS; // 例如: 0x1234...

if (!CONTRACT_ADDRESS) {
  console.error('请设置环境变量 CONTRACT_ADDRESS');
  process.exit(1);
}

if (!RPC_URL) {
  console.error('请设置环境变量 RPC_URL（或 SEPOLIA_RPC_URL）');
  process.exit(1);
}

let NORMALIZED_ADDRESS;
try {
  NORMALIZED_ADDRESS = getAddress(CONTRACT_ADDRESS);
} catch (e) {
  console.error('合约地址不合法，请检查 CONTRACT_ADDRESS:', CONTRACT_ADDRESS);
  process.exit(1);
}

const client = createPublicClient({
  transport: http(RPC_URL),
});

// 读取 storage slot 的辅助函数（返回 32 字节 hex，去掉 0x 后长度 64）
async function readSlot(address, slotBigInt) {
  const hex = await client.getStorageAt({
    address,
    slot: toHex(slotBigInt, { size: 32 }),
  });
  const body = (hex ?? '0x').slice(2).padStart(64, '0');
  return '0x' + body;
}

function calcArrayDataBaseSlot(slotIndexBigInt) {
  // dataOffset = keccak256( pad32(slot) )
  const slotHexPadded = toHex(slotIndexBigInt, { size: 32 });
  const baseHex = keccak256(slotHexPadded);
  return hexToBigInt(baseHex);
}

function decodeAddressAndUint64(slotHex32) {
  const body = slotHex32.slice(2); // 64 hex chars
  // address: 最后 20 字节（40 hex）
  const addrHex = '0x' + body.slice(64 - 40);
  // uint64: 紧邻地址左侧的 8 字节（16 hex）
  const startHex = '0x' + body.slice(64 - 40 - 16, 64 - 40);
  const user = getAddress(addrHex);
  const startTime = Number(hexToBigInt(startHex));
  return { user, startTime };
}

(async () => {
  try {
    // 数组槽位 p = 0（本合约布局如此；若有变更请调整）
    const p = 0n;

    // 读取长度：slot p
    const lenHex = await readSlot(NORMALIZED_ADDRESS, p);
    const length = Number(hexToBigInt(lenHex));

    // 计算元素起始基址：keccak256(pad32(p))
    const base = calcArrayDataBaseSlot(p);

    for (let i = 0; i < length; i++) {
      const idx = BigInt(i);
      const slotA = base + idx * 2n;
      const slotB = slotA + 1n;

      const sA = await readSlot(NORMALIZED_ADDRESS, slotA);
      const sB = await readSlot(NORMALIZED_ADDRESS, slotB);

      const { user, startTime } = decodeAddressAndUint64(sA);
      const amount = hexToBigInt(sB);

      console.log(`locks[${i}]: user:${user}, startTime:${startTime}, amount:${amount.toString()}`);
    }
  } catch (err) {
    console.error('读取失败:', err);
    process.exit(1);
  }
})();