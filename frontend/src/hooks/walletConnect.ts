import { useState } from "react";
import { BrowserProvider } from "ethers";

export function useWallet() {
    const [account, setAccount] = useState<string | null>(null);

    async function connectWallet() {
        if (!window.ethereum) throw new Error("MetaMask isn't installed");
        const provider = new BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();
        const address = await signer.getAddress();
        setAccount(address);
    }

    async function disconnectWallet() {
        if (!window.ethereum) return;

        await window.ethereum.request({
            method: "wallet_revokePermissions",
            params: [{ eth_accounts: {} }]
        });

        setAccount(null);
    }

    return { account, connectWallet, disconnectWallet };
}