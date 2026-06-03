import { useState, type SubmitEvent } from "react";
import { withdrawUsdc } from "../contracts/autoDca";

type WithdrawFormProps = {
    onSuccess: () => Promise<void>;
};

export function WithdrawForm({ onSuccess }: WithdrawFormProps) {
    const [amount, setAmount] = useState("");

    async function handleSubmit(event: SubmitEvent<HTMLFormElement>) {
        event.preventDefault();
        await withdrawUsdc(amount);
        await onSuccess();
        setAmount("");
    }

    return (
        <form onSubmit={handleSubmit}>
            <h2>Withdraw</h2>
            <input type="number" placeholder="USDC amount" value={amount} onChange={(event) => setAmount(event.target.value)} required />
            <button type="submit">Withdraw</button>
        </form>
    );
}