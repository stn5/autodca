import { ethers } from "ethers";
import { handleOrderCreated, handleOrderUpdated, handleOrderCancelled, handleOrderExecuted } from "./handlers";

async function syncPastEvents(autoDca: ethers.Contract, fromBlock: number) {
    const events = await Promise.all([
        autoDca.queryFilter(autoDca.filters.OrderCreated(), fromBlock),
        autoDca.queryFilter(autoDca.filters.OrderUpdated(), fromBlock),
        autoDca.queryFilter(autoDca.filters.OrderCancelled(), fromBlock),
        autoDca.queryFilter(autoDca.filters.OrderExecuted(), fromBlock)
    ]);

    const sortedEvents = events.flat().sort((a, b) => {
        if (a.blockNumber !== b.blockNumber) {
            return a.blockNumber - b.blockNumber;
        }
        return a.index - b.index;
    });

    for (const event of sortedEvents) {
        const parsedEvent = event as ethers.EventLog;
        const args = parsedEvent.args;
        const eventName = parsedEvent.fragment.name;

        if (eventName === "OrderCreated") {
            await handleOrderCreated(
                args.orderId,
                args.user,
                args.tokenToBuy,
                args.usdcAmountPerSwap,
                args.interval,
                args.createdAt,
                parsedEvent.transactionHash,
                parsedEvent.blockNumber
            );
        } else if (eventName === "OrderUpdated") {
            await handleOrderUpdated(
                args.orderId,
                args.usdcAmountPerSwap,
                args.interval,
                parsedEvent.transactionHash,
                parsedEvent.blockNumber
            );
        } else if (eventName === "OrderCancelled") {
            await handleOrderCancelled(
                args.orderId,
                parsedEvent.transactionHash,
                parsedEvent.blockNumber
            );
        } else if (eventName === "OrderExecuted") {
            await handleOrderExecuted(
                args.orderId,
                args.user,
                args.tokenToBuy,
                args.usdcAmountSpent,
                args.tokenAmountReceived,
                args.executedAt,
                parsedEvent.transactionHash,
                parsedEvent.blockNumber
            );
        }
    }
    console.log(`Past events synced from block ${fromBlock}`);
}

export { syncPastEvents }