window.ERC20PermitABI = [
    { "name": "name", "type": "function", "stateMutability": "view", "inputs": [], "outputs": [{ "internalType": "string", "name": "", "type": "string" }] },
    { "name": "nonces", "type": "function", "stateMutability": "view", "inputs": [{ "internalType": "address", "name": "owner", "type": "address" }], "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }] },
    { "name": "allowance", "type": "function", "stateMutability": "view", "inputs": [ { "internalType": "address", "name": "owner", "type": "address" }, { "internalType": "address", "name": "spender", "type": "address" } ], "outputs": [ { "internalType": "uint256", "name": "", "type": "uint256" } ] },
    { "name": "approve", "type": "function", "stateMutability": "nonpayable", "inputs": [ { "internalType": "address", "name": "spender", "type": "address" }, { "internalType": "uint256", "name": "value", "type": "uint256" } ], "outputs": [ { "internalType": "bool", "name": "", "type": "bool" } ] },
    { "name": "transferFrom", "type": "function", "stateMutability": "nonpayable", "inputs": [ { "internalType": "address", "name": "from", "type": "address" }, { "internalType": "address", "name": "to", "type": "address" }, { "internalType": "uint256", "name": "value", "type": "uint256" } ], "outputs": [ { "internalType": "bool", "name": "", "type": "bool" } ] },
    { "name": "DOMAIN_SEPARATOR", "type": "function", "stateMutability": "view", "inputs": [], "outputs": [{ "internalType": "bytes32", "name": "", "type": "bytes32" }] },
    { "name": "permit", "type": "function", "stateMutability": "nonpayable", "inputs": [ { "internalType": "address", "name": "owner", "type": "address" }, { "internalType": "address", "name": "spender", "type": "address" }, { "internalType": "uint256", "name": "value", "type": "uint256" }, { "internalType": "uint256", "name": "deadline", "type": "uint256" }, { "internalType": "uint8", "name": "v", "type": "uint8" }, { "internalType": "bytes32", "name": "r", "type": "bytes32" }, { "internalType": "bytes32", "name": "s", "type": "bytes32" } ], "outputs": [] }
];


