import { useWallet } from "../hooks/walletConnect";

export function WalletButton() {
    const { account, connectWallet } = useWallet();

    return (
        <button onClick={connectWallet}>
            {account ? `...${account.slice(-4)}` : "Connect Wallet"}
        </button>
    );
}