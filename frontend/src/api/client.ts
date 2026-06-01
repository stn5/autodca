const API_URL = import.meta.env.VITE_API_URL ?? "http://localhost:3000/api";

export type Token = {
    tokenAddress: string;
    isAllowed: boolean;
    priceFeedAddress: string;
    tokenDecimals: number;
};

export type UserBalance = {
    userAddress: string;
    usdcBalance: string;
};

export type Order = {
    order_id: string;
    user_address: string;
    token_address: string;
    usdc_amount_per_swap: string;
    interval_seconds: string;
    last_executed: string;
    is_active: boolean;
    tx_hash: string;
    block_number: string;
    updated_at: string;
};

export type Execution = {
    id: number;
    order_id: string;
    user_address: string;
    token_address: string;
    usdc_amount_spent: string;
    token_amount_received: string;
    executed_at: string;
    tx_hash: string;
    block_number: string;
};

async function request<T>(path: string): Promise<T> {
    const res = await fetch(`${API_URL}${path}`);
    if (!res.ok) throw new Error(`API request failed: ${res.status}`);
    return res.json();
}

export function getTokens() {
    return request<Token[]>("/tokens");
}

export function getUserBalance(userAddress: string) {
    return request<UserBalance>(`/users/${userAddress}/balance`);
}

export function getUserOrders(userAddress: string) {
    return request<Order[]>(`/users/${userAddress}/orders`);
}

export function getUserExecutions(userAddress: string) {
    return request<Execution[]>(`/users/${userAddress}/executions`);
}

export function getOrderExecutions(orderId: string) {
    return request<Execution[]>(`/orders/${orderId}/executions`);
}
