export const autoDcaAbi = [
    "event OrderCreated(uint256 indexed orderId, address indexed user, address indexed tokenToBuy, uint256 usdcAmountPerSwap, uint256 interval, uint256 createdAt)",
    "event OrderUpdated(uint256 indexed orderId, uint256 usdcAmountPerSwap, uint256 interval)",
    "event OrderCancelled(uint256 indexed orderId)",
    "event OrderExecuted(uint256 indexed orderId, address indexed user, address indexed tokenToBuy, uint256 usdcAmountSpent, uint256 tokenAmountReceived, uint256 executedAt)"
];