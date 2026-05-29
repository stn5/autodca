import { query } from "../db";

async function handleOrderCreated(
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

async function handleOrderUpdated(
    orderId: bigint,
    usdcAmountPerSwap: bigint,
    interval: bigint,
    txHash: string,
    blockNumber: number
) {
    await query(
        `UPDATE orders
        SET
            usdc_amount_per_swap = $2,
            interval_seconds = $3,
            tx_hash = $4,
            block_number = $5,
            updated_at = NOW()
        WHERE order_id = $1`,
        [
            orderId.toString(),
            usdcAmountPerSwap.toString(),
            interval.toString(),
            txHash,
            blockNumber
        ]
    );
}

async function handleOrderCancelled(
    orderId: bigint,
    txHash: string,
    blockNumber: number
) {
    await query(
        `UPDATE orders
        SET
            is_active = false,
            tx_hash = $2,
            block_number = $3,
            updated_at = NOW()
        WHERE order_id = $1`,
        [
            orderId.toString(),
            txHash,
            blockNumber
        ]
    );
}

async function handleOrderExecuted(
    orderId: bigint,
    user: string,
    tokenToBuy: string,
    usdcAmountSpent: bigint,
    tokenAmountReceived: bigint,
    executedAt: bigint,
    txHash: string,
    blockNumber: number
) {
    await query(
        `INSERT INTO executions (
            order_id,
            user_address,
            token_address,
            usdc_amount_spent,
            token_amount_received,
            executed_at,
            tx_hash,
            block_number
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        [
            orderId.toString(),
            user.toLowerCase(),
            tokenToBuy.toLowerCase(),
            usdcAmountSpent.toString(),
            tokenAmountReceived.toString(),
            executedAt.toString(),
            txHash,
            blockNumber
        ]
    );

    await query(
        `UPDATE orders
        SET
            last_executed = $2,
            tx_hash = $3,
            block_number = $4,
            updated_at = NOW()
        WHERE order_id = $1`,
        [
            orderId.toString(),
            executedAt.toString(),
            txHash,
            blockNumber
        ]
    );
}

export { handleOrderCreated, handleOrderUpdated, handleOrderCancelled, handleOrderExecuted }