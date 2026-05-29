import "dotenv/config";
import { ethers } from "ethers";
import { autoDcaAbi } from "../contracts/autoDcaAbi";
import { handleOrderCreated } from "./handlers";

const { RPC_URL, AUTO_DCA_ADDRESS } = process.env;

if (!RPC_URL) throw new Error("RPC_URL isn't set");
if (!AUTO_DCA_ADDRESS) throw new Error("AUTO_DCA_ADDRESS isn't set");

const provider = new ethers.JsonRpcProvider(RPC_URL);
const autoDca = new ethers.Contract(AUTO_DCA_ADDRESS, autoDcaAbi, provider);

async function onOrderCreated(
    orderId: bigint,
    user: string,
    tokenToBuy: string,
    usdcAmountPerSwap: bigint,
    interval: bigint,
    createdAt: bigint,
    event: ethers.EventLog
) {
    try {
        await handleOrderCreated(
            orderId,
            user,
            tokenToBuy,
            usdcAmountPerSwap,
            interval,
            createdAt,
            event.transactionHash,
            event.blockNumber
        );
        console.log(`Indexed OrderCreated: ${orderId.toString()}`);
    } catch (error) {
        console.log("Failed to index OrderCreated:", error);
    }
}

function startIndexer() {
    console.log(`Indexer listening AutoDCA: ${AUTO_DCA_ADDRESS}`);
    autoDca.on("OrderCreated", onOrderCreated);
}

startIndexer();