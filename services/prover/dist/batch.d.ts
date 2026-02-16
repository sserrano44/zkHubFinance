import type { QueuedAction, SettlementBatchPayload } from "./types";
export declare function buildBatch(batchId: bigint, hubChainId: bigint, spokeChainId: bigint, actions: QueuedAction[]): SettlementBatchPayload;
