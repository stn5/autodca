CREATE TABLE IF NOT EXISTS tokens (
    token_address TEXT PRIMARY KEY,
    token_decimals INTEGER NOT NULL,
    price_feed_address TEXT NOT NULL,
    is_allowed BOOLEAN NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS orders (
    order_id NUMERIC PRIMARY KEY,
    user_address TEXT NOT NULL,
    token_address TEXT NOT NULL,
    usdc_amount_per_swap NUMERIC NOT NULL,
    interval_seconds NUMERIC NOT NULL,
    last_executed NUMERIC NOT NULL,
    is_active BOOLEAN NOT NULL,
    tx_hash TEXT NOT NULL,
    block_number NUMERIC NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS executions (
    id SERIAL PRIMARY KEY,
    order_id NUMERIC NOT NULL REFERENCES orders(order_id),
    user_address TEXT NOT NULL,
    token_address TEXT NOT NULL,
    usdc_amount_spent NUMERIC NOT NULL,
    token_amount_received NUMERIC NOT NULL,
    executed_at NUMERIC NOT NULL,
    tx_hash TEXT NOT NULL,
    block_number NUMERIC NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_orders_user_address ON orders(user_address);
CREATE INDEX IF NOT EXISTS idx_executions_user_address ON executions(user_address);
CREATE INDEX IF NOT EXISTS idx_executions_order_id ON executions(order_id);