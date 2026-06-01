import { Router } from "express";
import { ethers } from "ethers";
import { query } from "../db";
import { provider } from "../lib/providers";
import { autoDcaAbi } from "../contracts/autoDcaAbi";
const { AUTO_DCA_ADDRESS } = process.env;

if (!AUTO_DCA_ADDRESS) {
    throw new Error("AUTO_DCA_ADDRESS isn't set");
}

const autoDca = new ethers.Contract(AUTO_DCA_ADDRESS, autoDcaAbi, provider);

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

router.get("/users/:userAddress/balance", async (req, res) => {
    try {
        const { userAddress } = req.params;
        const balance: bigint = await autoDca.userBalances(userAddress);

        res.json({
            userAddress: userAddress.toLowerCase(),
            usdcBalance: balance.toString()
        });
    } catch (error) {
        console.error("Failed to fetch user balance:", error);
        res.status(500).json({ error: "Failed to fetch user balance" });
    }
});

router.get("/tokens", async (req, res) => {
    try {
        const tokenAddresses: string[] = await autoDca.getAllowedTokens();

        const tokens = await Promise.all(
            tokenAddresses.map(async (tokenAddress) => {
                const token = await autoDca.allowedTokens(tokenAddress);

                return {
                    tokenAddress: tokenAddress.toLowerCase(),
                    isAllowed: token.isAllowed,
                    priceFeedAddress: token.priceFeedAddress.toLowerCase(),
                    tokenDecimals: Number(token.tokenDecimals)
                };
            })
        );

        res.json(tokens.filter((token) => token.isAllowed));
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