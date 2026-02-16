import { type PublicClient, type WalletClient } from "viem";
import type { Intent, IntentLifecycle, ProtocolAddresses } from "./types";
export type HubPosition = {
    collateral: Array<{
        asset: `0x${string}`;
        amount: bigint;
    }>;
    debt: Array<{
        asset: `0x${string}`;
        amount: bigint;
    }>;
    healthFactor: bigint;
};
export declare function createHubPublicClient(rpcUrl: string): PublicClient;
export declare function createSpokePublicClient(rpcUrl: string): PublicClient;
export declare function readHubPosition(client: PublicClient, addresses: ProtocolAddresses, user: `0x${string}`, assets: `0x${string}`[]): Promise<HubPosition>;
export declare function signIntent(walletClient: WalletClient, hubChainId: number, intentInbox: `0x${string}`, intent: Intent): Promise<`0x${string}`>;
export declare function fetchIntentStatus(indexerApiUrl: string, intentId: string): Promise<IntentLifecycle | null>;
export declare function fetchActivity(indexerApiUrl: string, user?: string): Promise<IntentLifecycle[]>;
export declare function submitSignedIntent(relayerApiUrl: string, payload: {
    intent: Intent;
    signature: `0x${string}`;
    relayerFee: bigint;
}): Promise<any>;
