import type { Execution } from "../api";
import { formatDate, formatUsdc } from "../helpers/format";

type ExecutionsTableProps = {
    executions: Execution[];
};

export function ExecutionsTable({ executions }: ExecutionsTableProps) {
    <h2>Purchase history</h2>
    if (!executions.length) {
        return (
            <section>
                <h2>Purchase history</h2>
                <p>No purchases found</p>
            </section>
        );
    }

    return (
        <section>
            <h2>Purchase history</h2>

            <table>
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Date</th>
                        <th>Token</th>
                        <th>USDC spent</th>
                        <th>Received</th>
                        <th>Tx</th>
                    </tr>
                </thead>

                <tbody>
                    {executions.map((execution, index) => (
                        <tr key={execution.id}>
                            <td>{index + 1}</td>
                            <td>{formatDate(execution.executed_at)}</td>
                            <td>{execution.token_address}</td>
                            <td>${formatUsdc(execution.usdc_amount_spent)}</td>
                            <td>{execution.token_amount_received}</td>
                            <td>{execution.tx_hash.slice(0, 10)}...</td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </section>
    );
}