import { useState, type SubmitEvent } from "react";
import { type Token } from "../api";
import { createOrder } from "../contracts/autoDca";

type CreateOrderFormProps = {
    tokens: Token[];
    onCreated: () => Promise<void>;
};

export function CreateOrderForm({ tokens, onCreated }: CreateOrderFormProps) {
    const [tokenAddress, setTokenAddress] = useState("");
    const [usdcAmount, setUsdcAmount] = useState("");
    const [intervalSeconds, setIntervalSeconds] = useState("86400");

    async function handleSubmit(event: SubmitEvent<HTMLFormElement>) {
        event.preventDefault();
        await createOrder(tokenAddress, usdcAmount, intervalSeconds);
        await new Promise((resolve) => setTimeout(resolve, 2500));
        await onCreated();
        setUsdcAmount("");
    }

    return (
        <form onSubmit={handleSubmit}>
            <h2>Create order</h2>

            <select value={tokenAddress} onChange={(event) => setTokenAddress(event.target.value)} required>
                <option value="">Select token</option>
                {tokens.map((token) => (
                    <option key={token.tokenAddress} value={token.tokenAddress}>
                        {token.tokenAddress}
                    </option>
                ))}
            </select>

            <input type="number" placeholder="USDC per swap" value={usdcAmount} onChange={(event) => setUsdcAmount(event.target.value)} required />

            <select value={intervalSeconds} onChange={(event) => setIntervalSeconds(event.target.value)}>
                <option value="86400">1 day</option>
                <option value="259200">3 days</option>
                <option value="604800">1 week</option>
                <option value="1209600">2 weeks</option>
                <option value="2592000">1 month</option>
            </select>

            <button type="submit">Create order</button>
        </form>
    );
}