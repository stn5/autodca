import { useEffect, useState } from "react";
import { getTokens, getUserBalance, getUserOrders, getUserExecutions, type Token, type UserBalance, type Order, type Execution } from "../api";
import { formatUsdc } from "../helpers/format";
import { OrdersTable } from "../components/OrdersTable";
import { ExecutionsTable } from "../components/ExecutionsTable";
import { CreateOrderForm } from "../components/CreateOrderForm";
import { DepositForm } from "../components/DepositForm";
import { WithdrawForm } from "../components/WithdrawForm";
import { getWalletUsdcBalance } from "../contracts/autoDca";

type DashboardProps = {
    account: string;
};

export function Dashboard({ account }: DashboardProps) {
    const [tokens, setTokens] = useState<Token[]>([]);
    const [balance, setBalance] = useState<UserBalance | null>(null);
    const [orders, setOrders] = useState<Order[]>([]);
    const [executions, setExecutions] = useState<Execution[]>([]);
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

    return (
        <section>
            <p>Connected: {account}</p>
            <p>Wallet balance: ${formatUsdc(walletUsdcBalance)}</p>
            <p>Contract balance: ${formatUsdc(balance?.usdcBalance ?? "0")}</p>
            <p>Orders: {orders.length}</p>
            <OrdersTable title="Active orders" orders={activeOrders} />
            <OrdersTable title="Cancelled orders" orders={cancelledOrders} />
            <ExecutionsTable executions={executions} />
            <CreateOrderForm tokens={tokens} onCreated={reloadOrders} />
            <DepositForm onSuccess={reloadBalances} />
            <WithdrawForm onSuccess={reloadBalances} />
        </section>
    );
}