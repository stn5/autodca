import "dotenv/config";
import { ethers } from "ethers";
import { autoDcaAbi } from "../contracts/autoDcaAbi";
import { handleOrderCreated, handleOrderUpdated, handleOrderCancelled, handleOrderExecuted } from "./handlers";
import { syncPastEvents } from "./syncPastEvents";

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
    event: ethers.ContractEventPayload
) {
    try {
        await handleOrderCreated(
            orderId,
            user,
            tokenToBuy,
            usdcAmountPerSwap,
            interval,
            createdAt,
            event.log.transactionHash,
            event.log.blockNumber
        );
        console.log(`Indexed OrderCreated: ${orderId.toString()}`);
    } catch (error) {
        console.log("Failed to index OrderCreated:", error);
    }
}

async function onOrderUpdated(
    orderId: bigint,
    usdcAmountPerSwap: bigint,
    interval: bigint,
    event: ethers.ContractEventPayload
) {
    try {
        await handleOrderUpdated(
            orderId,
            usdcAmountPerSwap,
            interval,
            event.log.transactionHash,
            event.log.blockNumber
        );
        console.log(`Indexed OrderUpdated: ${orderId.toString()}`);
    } catch (error) {
        console.error("Failed to index OrderUpdated:", error);
    }
}

async function onOrderCancelled(orderId: bigint, event: ethers.ContractEventPayload) {
    try {
        await handleOrderCancelled(
            orderId,
            event.log.transactionHash,
            event.log.blockNumber
        );
        console.log(`Indexed OrderCancelled: ${orderId.toString()}`);
    } catch (error) {
        console.error("Failed to index OrderCancelled:", error);
    }
}

async function onOrderExecuted(
    orderId: bigint,
    user: string,
    tokenToBuy: string,
    usdcAmountSpent: bigint,
    tokenAmountReceived: bigint,
    executedAt: bigint,
    event: ethers.ContractEventPayload
) {
    try {
        await handleOrderExecuted(
            orderId,
            user,
            tokenToBuy,
            usdcAmountSpent,
            tokenAmountReceived,
            executedAt,
            event.log.transactionHash,
            event.log.blockNumber
        );
        console.log(`Indexed OrderExecuted: ${orderId.toString()}`);
    } catch (error) {
        console.error("Failed to index OrderExecuted:", error);
    }
}

function startLiveListeners() {
    console.log(`Indexer listening AutoDCA: ${AUTO_DCA_ADDRESS}`);
    autoDca.on("OrderCreated", onOrderCreated);
    autoDca.on("OrderUpdated", onOrderUpdated);
    autoDca.on("OrderCancelled", onOrderCancelled);
    autoDca.on("OrderExecuted", onOrderExecuted);
}

async function startIndexer() {
    const fromBlock = Number(0);

    await syncPastEvents(autoDca, fromBlock);
    startLiveListeners();
}

startIndexer().catch((error) => {
    console.error("Indexer failed:", error);
    process.exit(1);
});