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

    return { account, connectWallet };
}