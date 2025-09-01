import React, { useState } from 'react';
import './TransferForm.css';

const TransferForm = ({ onTransfer, loading, balance }) => {
  const [toAddress, setToAddress] = useState('');
  const [amount, setAmount] = useState('');
  const [errors, setErrors] = useState({});

  const validateForm = () => {
    const newErrors = {};

    // 验证地址
    if (!toAddress) {
      newErrors.toAddress = '请输入接收地址';
    } else if (!/^0x[a-fA-F0-9]{40}$/.test(toAddress)) {
      newErrors.toAddress = '请输入有效的以太坊地址';
    }

    // 验证金额
    if (!amount) {
      newErrors.amount = '请输入转账金额';
    } else if (isNaN(amount) || parseFloat(amount) <= 0) {
      newErrors.amount = '请输入有效的金额';
    } else if (parseFloat(amount) > parseFloat(balance)) {
      newErrors.amount = '余额不足';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    
    if (validateForm()) {
      onTransfer(toAddress, amount);
      setToAddress('');
      setAmount('');
    }
  };

  return (
    <div className="card">
      <h2>转账</h2>
      <form onSubmit={handleSubmit}>
        <div className="form-group">
          <label htmlFor="toAddress">接收地址</label>
          <input
            type="text"
            id="toAddress"
            className={`input ${errors.toAddress ? 'error' : ''}`}
            value={toAddress}
            onChange={(e) => setToAddress(e.target.value)}
            placeholder="0x..."
            disabled={loading}
          />
          {errors.toAddress && <span className="error-text">{errors.toAddress}</span>}
        </div>

        <div className="form-group">
          <label htmlFor="amount">转账金额 (MTK)</label>
          <input
            type="number"
            id="amount"
            className={`input ${errors.amount ? 'error' : ''}`}
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="0.0"
            step="0.000001"
            disabled={loading}
          />
          {errors.amount && <span className="error-text">{errors.amount}</span>}
          <div className="balance-info">
            可用余额: {parseFloat(balance).toFixed(6)} MTK
          </div>
        </div>

        <button 
          type="submit" 
          className="btn transfer-btn"
          disabled={loading}
        >
          {loading ? '转账中...' : '确认转账'}
        </button>
      </form>
    </div>
  );
};

export default TransferForm;
