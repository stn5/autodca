import { BrowserProvider, Contract, parseUnits } from "ethers";
import { autoDcaAbi, erc20Abi } from "./abi";

const AUTO_DCA_ADDRESS = import.meta.env.VITE_AUTO_DCA_ADDRESS;
const USDC_ADDRESS = import.meta.env.VITE_USDC_ADDRESS;

if (!AUTO_DCA_ADDRESS) throw new Error("VITE_AUTO_DCA_ADDRESS isn't set");
if (!USDC_ADDRESS) throw new Error("VITE_USDC_ADDRESS isn't set");

async function getSigner() {
    if (!window.ethereum) throw new Error("MetaMask isn't installed");
    const provider = new BrowserProvider(window.ethereum);
    return provider.getSigner();
}

async function getAutoDcaContract() {
    const signer = await getSigner();
    return new Contract(AUTO_DCA_ADDRESS, autoDcaAbi, signer);
}

async function getUsdcContract() {
    const signer = await getSigner();
    return new Contract(USDC_ADDRESS, erc20Abi, signer);
}

export async function createOrder(tokenAddress: string, usdcAmount: string, intervalSeconds: string) {
    const autoDca = await getAutoDcaContract();

    const tx = await autoDca.createOrder(tokenAddress, parseUnits(usdcAmount, 6), intervalSeconds);
    await tx.wait();
}

export async function cancelOrder(orderId: string) {
    const autoDca = await getAutoDcaContract();

    const tx = await autoDca.cancelOrder(orderId);
    await tx.wait();
}

export async function depositUsdc(amount: string) {
    const usdc = await getUsdcContract();
    const autoDca = await getAutoDcaContract();
    const parsedAmount = parseUnits(amount, 6);

    const approveTx = await usdc.approve(AUTO_DCA_ADDRESS, parsedAmount);
    await approveTx.wait();

    const depositTx = await autoDca.deposit(parsedAmount);
    await depositTx.wait();
}

export async function withdrawUsdc(amount: string) {
    const autoDca = await getAutoDcaContract();

    const tx = await autoDca.withdraw(parseUnits(amount, 6));
    await tx.wait();
}

export async function getWalletUsdcBalance(account: string) {
    const usdc = await getUsdcContract();

    const balance: bigint = await usdc.balanceOf(account);
    return balance.toString();
}