import { useWallet } from "./hooks/walletConnect";
import { WalletButton } from "./components/WalletButton";
import { Dashboard } from "./pages/Dashboard";

function App() {
    const wallet = useWallet();

    return (
        <main className="app">
            <header>
                <h1>AutoDCA</h1>
                <WalletButton account={wallet.account} connectWallet={wallet.connectWallet} />
            </header>
            {wallet.account && <Dashboard account={wallet.account} />}
        </main>
    );
}

export default App;