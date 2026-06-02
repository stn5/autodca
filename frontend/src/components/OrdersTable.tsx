import type { Order } from "../api";
import { formatInterval, formatUsdc } from "../helpers/format";

type OrdersTableProps = {
    title: string;
    orders: Order[];
    onCancel?: (orderId: string) => Promise<void>;
};

export function OrdersTable({ title, orders }: OrdersTableProps) {
    if (!orders.length) {
        return (
            <section>
                <h2>{title}</h2>
                <p>No orders found.</p>
            </section>
        );
    }

    return (
        <section>
            <h2>{title}</h2>

            <table>
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Token</th>
                        <th>$/swap</th>
                        <th>Interval</th>
                    </tr>
                </thead>

                <tbody>
                    {orders.map((order, index) => (
                        <tr key={order.order_id}>
                            <td>{index + 1}</td>
                            <td>{order.token_address}</td>
                            <td>${formatUsdc(order.usdc_amount_per_swap)}</td>
                            <td>{formatInterval(order.interval_seconds)}</td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </section>
    );
}