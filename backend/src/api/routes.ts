import { Router } from "express";
import { query } from "../db";

export const router = Router();

router.get("/checkConnection", (_req, res) => {
    res.json({ status: "ok" });
});

router.get("/orders/:userAddress", async (req, res) => {
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