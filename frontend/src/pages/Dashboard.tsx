import { useEffect, useState } from "react";
import { getTokens, getUserBalance, getUserOrders, getUserExecutions, type Token, type UserBalance, type Order, type Execution } from "../api";
import { formatUsdc } from "../helpers/format";
import { OrdersTable } from "../components/OrdersTable";
import { ExecutionsTable } from "../components/ExecutionsTable";
import { CreateOrderForm } from "../components/CreateOrderForm";
import { UpdateOrderForm } from "../components/UpdateOrderForm";
import { DepositForm } from "../components/DepositForm";
import { WithdrawForm } from "../components/WithdrawForm";
import { getWalletUsdcBalance, cancelOrder } from "../contracts/autoDca";

type DashboardProps = {
    account: string;
};

export function Dashboard({ account }: DashboardProps) {
    const [tokens, setTokens] = useState<Token[]>([]);
    const [balance, setBalance] = useState<UserBalance | null>(null);
    const [orders, setOrders] = useState<Order[]>([]);
    const [executions, setExecutions] = useState<Execution[]>([]);
    const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
    const [walletUsdcBalance, setWalletUsdcBalance] = useState("0");
    const activeOrders = orders.filter((order) => order.is_active);
    const cancelledOrders = orders.filter((order) => !order.is_active);

    useEffect(() => {
        async function loadDashboard() {
            const [tokensData, balanceData, ordersData, executionsData, walletUsdcBalanceData] =
                await Promise.all([
                    getTokens(),
                    getUserBalance(account),
                    getUserOrders(account),
                    getUserExecutions(account),
                    getWalletUsdcBalance(account)
                ]);

            setTokens(tokensData);
            setBalance(balanceData);
            setOrders(ordersData);
            setExecutions(executionsData);
            setWalletUsdcBalance(walletUsdcBalanceData);
        }

        loadDashboard();
    }, [account]);

    async function reloadOrders() {
        const ordersData = await getUserOrders(account);
        setOrders(ordersData);
    }

    async function reloadBalances() {
        const [balanceData, walletUsdcBalanceData] = await Promise.all([
            getUserBalance(account),
            getWalletUsdcBalance(account)
        ]);

        setBalance(balanceData);
        setWalletUsdcBalance(walletUsdcBalanceData);
    }

    async function handleOrderUpdated(orderId: string, usdcAmountPerSwap: string, intervalSeconds: string) {
        setOrders((currentOrders) =>
            currentOrders.map((order) =>
                order.order_id === orderId ? { ...order, usdc_amount_per_swap: usdcAmountPerSwap, interval_seconds: intervalSeconds } : order
            )
        );

        setSelectedOrder(null);
    }

    async function handleCancelOrder(orderId: string) {
        await cancelOrder(orderId);

        setOrders((currentOrders) =>
            currentOrders.map((order) =>
                order.order_id === orderId ? { ...order, is_active: false } : order
            )
        );
    }

    return (
        <section>
            <p>Connected: {account}</p>
            <p>Wallet balance: ${formatUsdc(walletUsdcBalance)}</p>
            <p>Contract balance: ${formatUsdc(balance?.usdcBalance ?? "0")}</p>
            <p>Active Orders: {activeOrders.length}</p>
            <OrdersTable title="Active orders" orders={activeOrders} onCancel={handleCancelOrder} onEdit={setSelectedOrder}/>
            <OrdersTable title="Cancelled orders" orders={cancelledOrders} />
            <ExecutionsTable executions={executions} />
            <CreateOrderForm tokens={tokens} onCreated={reloadOrders} />
            {selectedOrder && (
                <UpdateOrderForm key={selectedOrder.order_id} order={selectedOrder} onClose={() => setSelectedOrder(null)} onSuccess={handleOrderUpdated} />
            )}
            <DepositForm onSuccess={reloadBalances} />
            <WithdrawForm onSuccess={reloadBalances} />
        </section>
    );
}