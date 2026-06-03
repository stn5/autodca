import { useState, type SubmitEvent } from "react";
import { depositUsdc } from "../contracts/autoDca";

type DepositFormProps = {
    onSuccess: () => Promise<void>;
};

export function DepositForm({ onSuccess }: DepositFormProps) {
    const [amount, setAmount] = useState("");

    async function handleSubmit(event: SubmitEvent<HTMLFormElement>) {
        event.preventDefault();
        await depositUsdc(amount);
        await onSuccess();
        setAmount("");
    }

    return (
        <form onSubmit={handleSubmit}>
            <h2>Deposit</h2>
            <input type="number" placeholder="USDC amount" value={amount} onChange={(event) => setAmount(event.target.value)} required />
            <button type="submit">Deposit</button>
        </form>
    );
}