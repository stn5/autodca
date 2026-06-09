import { useState, type SubmitEvent } from "react";
import { formatUnits, parseUnits } from "ethers";
import { updateOrder } from "../contracts/autoDca";
import type { Order } from "../api";

type UpdateOrderFormProps = {
    order: Order;
    onClose: () => void;
    onSuccess: (orderId: string, usdcAmountPerSwap: string, intervalSeconds: string) => void;
};
export function UpdateOrderForm({ order, onClose, onSuccess }: UpdateOrderFormProps) {
    const [usdcAmount, setUsdcAmount] = useState(formatUnits(order.usdc_amount_per_swap, 6));
    const [intervalSeconds, setIntervalSeconds] = useState(order.interval_seconds);

    async function handleSubmit(event: SubmitEvent<HTMLFormElement>) {
        event.preventDefault();
        await updateOrder(order.order_id, usdcAmount, intervalSeconds);
        onSuccess(order.order_id, parseUnits(usdcAmount, 6).toString(), intervalSeconds);
    }

    return (
        <div className="modal">
            <div className="modal__content">
                <button type="button" onClick={onClose}>Close</button>

                <h3>Update order</h3>

                <form onSubmit={handleSubmit}>
                    <input type="number" value={usdcAmount} onChange={(event) => setUsdcAmount(event.target.value)} required />

                    <select value={intervalSeconds} onChange={(event) => setIntervalSeconds(event.target.value)}>
                        <option value="86400">1 day</option>
                        <option value="259200">3 days</option>
                        <option value="604800">1 week</option>
                        <option value="1209600">2 weeks</option>
                        <option value="2592000">1 month</option>
                    </select>

                    <button type="submit">Update</button>
                </form>
            </div>
        </div>
    );
}