/* global ethers, AppConfig, TokenBankABI, ERC20PermitABI */
(function () {
    const provider = window.ethereum ? new ethers.providers.Web3Provider(window.ethereum) : null;
    let signer = null;
    let userAddress = null;

    const els = {
        connectBtn: document.getElementById('connectBtn'),
        account: document.getElementById('account'),
        amountInput: document.getElementById('amountInput'),
        approveBtn: document.getElementById('approveBtn'),
        depositBtn: document.getElementById('depositBtn'),
        normalStatus: document.getElementById('normalStatus'),
        permitAmountInput: document.getElementById('permitAmountInput'),
        permitDepositBtn: document.getElementById('permitDepositBtn'),
        permitStatus: document.getElementById('permitStatus'),
        refreshBtn: document.getElementById('refreshBtn'),
        balance: document.getElementById('balance'),
    };

    function getContracts() {
        const bank = new ethers.Contract(AppConfig.bankAddress, TokenBankABI, signer || provider);
        const token = new ethers.Contract(AppConfig.tokenAddress, ERC20PermitABI, signer || provider);
        return { bank, token };
    }

    function setStatus(el, msg, type = 'muted') {
        el.className = `mono ${type}`;
        el.textContent = msg;
    }

    async function connect() {
        if (!provider) {
            alert('未检测到以太坊钱包，请安装 MetaMask');
            return;
        }
        const accounts = await provider.send('eth_requestAccounts', []);
        signer = provider.getSigner();
        userAddress = accounts[0];
        els.account.textContent = userAddress;
        try { await provider.send('wallet_switchEthereumChain', [{ chainId: AppConfig.chainIdHex }]); } catch (e) {}
        refreshBalance();
    }

    async function refreshBalance() {
        if (!userAddress) return;
        const { bank } = getContracts();
        try {
            const bal = await bank.getBalance(userAddress);
            els.balance.textContent = bal.toString();
        } catch (e) {
            els.balance.textContent = '读取失败';
        }
    }

    async function handleApprove() {
        const amount = ethers.BigNumber.from(els.amountInput.value || '0');
        if (amount.lte(0)) return setStatus(els.normalStatus, '金额必须大于 0', 'error');
        const { token } = getContracts();
        try {
            setStatus(els.normalStatus, '发送 approve 交易中...');
            const tx = await token.approve(AppConfig.bankAddress, amount);
            await tx.wait();
            setStatus(els.normalStatus, 'approve 成功', 'success');
        } catch (e) {
            setStatus(els.normalStatus, `approve 失败: ${e.message || e}`, 'error');
        }
    }

    async function handleDeposit() {
        const amount = ethers.BigNumber.from(els.amountInput.value || '0');
        if (amount.lte(0)) return setStatus(els.normalStatus, '金额必须大于 0', 'error');
        const { bank } = getContracts();
        try {
            setStatus(els.normalStatus, '发送 deposit 交易中...');
            const tx = await bank.deposit(amount);
            await tx.wait();
            setStatus(els.normalStatus, 'deposit 成功', 'success');
            refreshBalance();
        } catch (e) {
            setStatus(els.normalStatus, `deposit 失败: ${e.message || e}`, 'error');
        }
    }

    async function handlePermitDeposit() {
        const amount = ethers.BigNumber.from(els.permitAmountInput.value || '0');
        if (amount.lte(0)) return setStatus(els.permitStatus, '金额必须大于 0', 'error');
        const { bank, token } = getContracts();
        try {
            setStatus(els.permitStatus, '准备签名数据...');

            const [name, nonce, net] = await Promise.all([
                token.name(),
                token.nonces(userAddress),
                provider.getNetwork(),
            ]);
            const chainId = net.chainId;
            const deadline = Math.floor(Date.now() / 1000) + 60 * 10; // 10 分钟

            const domain = {
                name,
                version: '1',
                chainId,
                verifyingContract: AppConfig.tokenAddress,
            };
            const types = {
                Permit: [
                    { name: 'owner', type: 'address' },
                    { name: 'spender', type: 'address' },
                    { name: 'value', type: 'uint256' },
                    { name: 'nonce', type: 'uint256' },
                    { name: 'deadline', type: 'uint256' },
                ],
            };
            const values = {
                owner: userAddress,
                spender: AppConfig.bankAddress,
                value: amount.toString(),
                nonce: nonce.toString(),
                deadline: deadline.toString(),
            };

            setStatus(els.permitStatus, '请求钱包签名...');
            const signature = await signer._signTypedData(domain, types, values);
            const sig = ethers.utils.splitSignature(signature);

            // 预检（静态调用），有助于在钱包前看到具体的 revert 信息
            try {
                await bank.callStatic.permitDeposit(amount, deadline, sig.v, sig.r, sig.s);
            } catch (preErr) {
                setStatus(els.permitStatus, `预检失败: ${preErr.message || preErr}`, 'error');
                return;
            }

            setStatus(els.permitStatus, '发送 permitDeposit 交易中...');
            const tx = await bank.permitDeposit(amount, deadline, sig.v, sig.r, sig.s);
            await tx.wait();
            setStatus(els.permitStatus, 'permitDeposit 成功', 'success');
            refreshBalance();
        } catch (e) {
            setStatus(els.permitStatus, `permitDeposit 失败: ${e.message || e}`, 'error');
        }
    }

    els.connectBtn.addEventListener('click', connect);
    els.refreshBtn.addEventListener('click', refreshBalance);
    els.approveBtn.addEventListener('click', handleApprove);
    els.depositBtn.addEventListener('click', handleDeposit);
    els.permitDepositBtn.addEventListener('click', handlePermitDeposit);
})();


