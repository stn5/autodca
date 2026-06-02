import { formatUnits } from "ethers";

export function formatUsdc(value: string) {
    return formatUnits(value, 6);
}

export function formatTokenAmount(value: string, decimals: number) {
    return formatUnits(value, decimals);
}

export function formatInterval(seconds: string) {
    const value = Number(seconds);

    if (value % 86400 === 0) return `${value / 86400}d`;
    if (value % 3600 === 0) return `${value / 3600}h`;

    return `${value}s`;
}

export function formatDate(timestamp: string) {
    return new Date(Number(timestamp) * 1000).toLocaleDateString();
}
