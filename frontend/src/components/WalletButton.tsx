type WalletButtonProps = {
    account: string | null;
    connectWallet: () => Promise<void>;
    disconnectWallet: () => Promise<void>;
};

export function WalletButton({ account, connectWallet, disconnectWallet }: WalletButtonProps) {
    return (
        <button onClick={account ? disconnectWallet : connectWallet}>
            {account ? "Disconnect" : "Connect Wallet"}
        </button>
    );
}