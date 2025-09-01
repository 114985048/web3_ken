import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import axios from 'axios';
import TransferForm from './components/TransferForm';
import TransferHistory from './components/TransferHistory';
import ErrorBoundary from './components/ErrorBoundary';
import './App.css';

// 合约 ABI - 这里需要根据实际部署的合约地址和 ABI 进行调整
const CONTRACT_ABI = [
  "function transfer(address to, uint256 amount) returns (bool)",
  "function balanceOf(address account) view returns (uint256)",
  "function decimals() view returns (uint8)",
  "function symbol() view returns (string)"
];

// 合约地址 - 需要根据实际部署的地址进行修改
const CONTRACT_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3"; // 示例地址

function App() {
  const [account, setAccount] = useState('');
  const [provider, setProvider] = useState(null);
  const [contract, setContract] = useState(null);
  const [balance, setBalance] = useState('0');
  const [transfers, setTransfers] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  // 连接钱包
  const connectWallet = async () => {
    try {
      if (typeof window.ethereum !== 'undefined') {
        const accounts = await window.ethereum.request({
          method: 'eth_requestAccounts'
        });
        
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();
        const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);
        
        setAccount(accounts[0]);
        setProvider(provider);
        setContract(contract);
        
        // 获取余额
        await updateBalance(accounts[0], contract);
        
        // 获取转账记录
        await fetchTransfers(accounts[0]);
      } else {
        setError('请安装 MetaMask 钱包');
      }
    } catch (error) {
      console.error('连接钱包失败:', error);
      setError('连接钱包失败: ' + error.message);
    }
  };

  // 更新余额
  const updateBalance = async (userAddress, contractInstance) => {
    try {
      const balance = await contractInstance.balanceOf(userAddress);
      const decimals = await contractInstance.decimals();
      const formattedBalance = ethers.formatUnits(balance, decimals);
      setBalance(formattedBalance);
    } catch (error) {
      console.error('获取余额失败:', error);
    }
  };

  // 获取转账记录
  const fetchTransfers = async (userAddress) => {
    try {
      setLoading(true);
      const response = await axios.get(`http://localhost:8080/api/transfers/${userAddress}`);
      setTransfers(response.data);
    } catch (error) {
      console.error('获取转账记录失败:', error);
      setError('获取转账记录失败: ' + error.message);
    } finally {
      setLoading(false);
    }
  };

  // 执行转账
  const handleTransfer = async (toAddress, amount) => {
    try {
      setLoading(true);
      setError('');
      
      const decimals = await contract.decimals();
      const amountInWei = ethers.parseUnits(amount.toString(), decimals);
      
      const tx = await contract.transfer(toAddress, amountInWei);
      await tx.wait();
      
      // 更新余额
      await updateBalance(account, contract);
      
      // 刷新转账记录
      await fetchTransfers(account);
      
      alert('转账成功！');
    } catch (error) {
      console.error('转账失败:', error);
      setError('转账失败: ' + error.message);
    } finally {
      setLoading(false);
    }
  };

  // 监听账户变化
  useEffect(() => {
    if (typeof window.ethereum !== 'undefined') {
      window.ethereum.on('accountsChanged', (accounts) => {
        if (accounts.length > 0) {
          setAccount(accounts[0]);
          if (contract) {
            updateBalance(accounts[0], contract);
            fetchTransfers(accounts[0]);
          }
        } else {
          setAccount('');
          setProvider(null);
          setContract(null);
          setBalance('0');
          setTransfers([]);
        }
      });
    }
  }, [contract]);

  return (
    <div className="container">
      <header className="header">
        <h1>Kentoken 代币转账系统</h1>
        {!account ? (
          <button className="btn" onClick={connectWallet}>
            连接钱包
          </button>
        ) : (
          <div className="account-info">
            <span>账户: {account}</span>
            <span>余额: {balance} MTK</span>
          </div>
        )}
      </header>

      {error && (
        <div className="error-message">
          {error}
        </div>
      )}

      {account && (
        <>
          <TransferForm 
            onTransfer={handleTransfer}
            loading={loading}
            balance={balance}
          />
          
          <ErrorBoundary>
            <TransferHistory 
              transfers={transfers}
              loading={loading}
              userAddress={account}
            />
          </ErrorBoundary>
        </>
      )}
    </div>
  );
}

export default App;
