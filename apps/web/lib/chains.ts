import type { Chain } from "viem";

const HUB_RPC = process.env.NEXT_PUBLIC_HUB_RPC_URL ?? "http://127.0.0.1:8545";
const SPOKE_RPC = process.env.NEXT_PUBLIC_SPOKE_RPC_URL ?? "http://127.0.0.1:9545";

export const baseLocal: Chain = {
  id: Number(process.env.NEXT_PUBLIC_HUB_CHAIN_ID ?? 8453),
  name: "Base Local",
  nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
  rpcUrls: {
    default: { http: [HUB_RPC] },
    public: { http: [HUB_RPC] }
  }
};

export const worldLocal: Chain = {
  id: Number(process.env.NEXT_PUBLIC_SPOKE_CHAIN_ID ?? 480),
  name: "Worldchain Local",
  nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
  rpcUrls: {
    default: { http: [SPOKE_RPC] },
    public: { http: [SPOKE_RPC] }
  }
};
