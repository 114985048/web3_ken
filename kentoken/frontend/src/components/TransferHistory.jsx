import React from 'react';
import { ethers } from 'ethers';
import './TransferHistory.css';

const TransferHistory = ({ transfers, loading, userAddress }) => {
  const formatAddress = (address) => {
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  };

  const formatAmount = (amount) => {
    try {
      // 确保 amount 是字符串格式，避免大数溢出
      const amountStr = amount.toString();
      // 假设代币有18位小数
      const formatted = ethers.formatUnits(amountStr, 18);
      // 格式化为最多6位小数
      return parseFloat(formatted).toFixed(6);
    } catch (error) {
      console.error('格式化金额失败:', error, 'amount:', amount);
      // 如果格式化失败，尝试手动计算
      try {
        const amountNum = BigInt(amount);
        const divisor = BigInt(10 ** 18);
        const whole = amountNum / divisor;
        const fraction = amountNum % divisor;
        const fractionStr = fraction.toString().padStart(18, '0');
        const result = `${whole}.${fractionStr}`;
        // 格式化为最多6位小数
        return parseFloat(result).toFixed(6);
      } catch (fallbackError) {
        console.error('备用格式化也失败:', fallbackError);
        return '0.000000';
      }
    }
  };

  const formatTimestamp = (timestamp) => {
    if (!timestamp) return '未知';
    return new Date(timestamp).toLocaleString('zh-CN');
  };

  const getTransferType = (fromAddress) => {
    return fromAddress.toLowerCase() === userAddress.toLowerCase() ? '转出' : '转入';
  };

  const getTransferTypeClass = (fromAddress) => {
    return fromAddress.toLowerCase() === userAddress.toLowerCase() ? 'outgoing' : 'incoming';
  };

  if (loading) {
    return (
      <div className="card">
        <h2>转账记录</h2>
        <div className="loading">加载中...</div>
      </div>
    );
  }

  return (
    <div className="card">
      <h2>转账记录</h2>
      {transfers.length === 0 ? (
        <div className="no-transfers">
          暂无转账记录
        </div>
      ) : (
        <div className="transfers-container">
          <table className="table">
            <thead>
              <tr>
                <th>类型</th>
                <th>地址</th>
                <th>金额 (MTK)</th>
                <th>交易哈希</th>
                <th>区块号</th>
                <th>时间</th>
              </tr>
            </thead>
            <tbody>
              {transfers.map((transfer) => (
                <tr key={transfer.id}>
                  <td>
                    <span className={`transfer-type ${getTransferTypeClass(transfer.fromAddress)}`}>
                      {getTransferType(transfer.fromAddress)}
                    </span>
                  </td>
                  <td>
                    {getTransferType(transfer.fromAddress) === '转出' 
                      ? formatAddress(transfer.toAddress)
                      : formatAddress(transfer.fromAddress)
                    }
                  </td>
                  <td className="amount">
                    {formatAmount(transfer.amount)}
                  </td>
                  <td>
                    <a 
                      href={`https://etherscan.io/tx/${transfer.txHash}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="tx-hash"
                    >
                      {formatAddress(transfer.txHash)}
                    </a>
                  </td>
                  <td>{transfer.blockNumber}</td>
                  <td>{transfer.timestamp}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};

export default TransferHistory;
