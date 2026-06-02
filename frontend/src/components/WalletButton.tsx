type WalletButtonProps = {
    account: string | null;
    connectWallet: () => Promise<void>;
};

export function WalletButton({ account, connectWallet }: WalletButtonProps) {
    return (
        <button onClick={connectWallet}>
            {account ? `...${account.slice(-4)}` : "Connect Wallet"}
        </button>
    );
}