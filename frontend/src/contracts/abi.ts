export const autoDcaAbi = [
    "function createOrder(address tokenToBuy, uint256 usdcAmountPerSwap, uint256 interval)",
    "function updateOrder(uint256 orderId, uint256 usdcAmountPerSwap, uint256 interval)",
    "function cancelOrder(uint256 orderId)",
    "function deposit(uint256 amount)",
    "function withdraw(uint256 amount)"
];

export const erc20Abi = [
    "function approve(address spender, uint256 amount) returns (bool)",
    "function allowance(address owner, address spender) view returns (uint256)",
    "function balanceOf(address account) view returns (uint256)"
];