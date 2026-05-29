import { Router } from "express";
import { query } from "../db";

export const router = Router();

router.get("/checkConnection", (_req, res) => {
    res.json({ status: "ok" });
});

router.get("/users/:userAddress/orders", async (req, res) => {
    try {
        const { userAddress } = req.params;

        const result = await query(
            "SELECT * FROM orders WHERE user_address = $1 ORDER BY order_id DESC",
            [userAddress.toLowerCase()]
        );

        res.json(result.rows);
    } catch (error) {
        console.error("Failed to fetch orders:", error);
        res.status(500).json({ error: "Failed to fetch orders" });
    }
});

router.get("/tokens", async (req, res) => {
    try {
        const result = await query(
            "SELECT * FROM tokens WHERE is_allowed = true ORDER BY token_address ASC"
        );

        res.json(result.rows);
    } catch (error) {
        console.error("Failed to fetch tokens:", error);
        res.status(500).json({ error: "Failed to fetch tokens" });
    }
});

router.get("/orders/:orderId/executions", async (req, res) => {
    try {
        const { orderId } = req.params;

        const result = await query(
            "SELECT * FROM executions WHERE order_id = $1 ORDER BY executed_at DESC",
            [orderId]
        );

        res.json(result.rows);
    } catch (error) {
        console.error("Failed to fetch order executions:", error);
        res.status(500).json({ error: "Failed to fetch order executions" });
    }
});

router.get("/users/:userAddress/executions", async (req, res) => {
    try {
        const { userAddress } = req.params;

        const result = await query(
            "SELECT * FROM executions WHERE user_address = $1 ORDER BY executed_at DESC",
            [userAddress.toLowerCase()]
        );

        res.json(result.rows);
    } catch (error) {
        console.error("Failed to fetch executions:", error);
        res.status(500).json({ error: "Failed to fetch executions" });
    }
});