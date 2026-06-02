import { useEffect, useState } from "react";
import { getUserBalance, getUserOrders, getUserExecutions, type UserBalance, type Order, type Execution } from "../api";
import { formatUsdc } from "../helpers/format";
import { OrdersTable } from "../components/OrdersTable";
import { ExecutionsTable } from "../components/ExecutionsTable";


type DashboardProps = {
    account: string;
};

export function Dashboard({ account }: DashboardProps) {
    const [balance, setBalance] = useState<UserBalance | null>(null);
    const [orders, setOrders] = useState<Order[]>([]);
    const [executions, setExecutions] = useState<Execution[]>([]);
    const activeOrders = orders.filter((order) => order.is_active);
    const cancelledOrders = orders.filter((order) => !order.is_active);

    useEffect(() => {
        async function loadDashboard() {
            const [balanceData, ordersData, executionsData] =
                await Promise.all([
                    getUserBalance(account),
                    getUserOrders(account),
                    getUserExecutions(account)
                ]);

            setBalance(balanceData);
            setOrders(ordersData);
            setExecutions(executionsData);
        }

        loadDashboard();
    }, [account]);

    return (
        <section>
            <p>Connected: {account}</p>
            <p>Contract balance: ${formatUsdc(balance?.usdcBalance ?? "0")}</p>
            <p>Orders: {orders.length}</p>
            <OrdersTable title="Active orders" orders={activeOrders} />
            <OrdersTable title="Cancelled orders" orders={cancelledOrders} />
            <ExecutionsTable executions={executions} />
        </section>
    );
}