import { query } from "../db";

export async function handleOrderCreated(
    orderId: bigint,
    user: string,
    tokenToBuy: string,
    usdcAmountPerSwap: bigint,
    interval: bigint,
    createdAt: bigint,
    txHash: string,
    blockNumber: number
) {
    await query(
        `INSERT INTO orders (
            order_id,
            user_address,
            token_address,
            usdc_amount_per_swap,
            interval_seconds,
            last_executed,
            is_active,
            tx_hash,
            block_number
        )
        VALUES ($1, $2, $3, $4, $5, $6, true, $7, $8)
        ON CONFLICT (order_id) DO NOTHING`,
        [
            orderId.toString(),
            user.toLowerCase(),
            tokenToBuy.toLowerCase(),
            usdcAmountPerSwap.toString(),
            interval.toString(),
            createdAt.toString(),
            txHash,
            blockNumber
        ]
    );
}