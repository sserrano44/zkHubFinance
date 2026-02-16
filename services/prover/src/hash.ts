import { numberToHex } from "viem";
import type { SettlementBatchPayload } from "./types";

export const MAX_BATCH_ACTIONS = 50;
export const SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617n;
const HASH_BETA = 1315423911n;
const HASH_C = 11400714819323198485n;

const INTENT_SUPPLY = 1n;
const INTENT_REPAY = 2n;
const INTENT_BORROW = 3n;
const INTENT_WITHDRAW = 4n;

export function toField(value: bigint): bigint {
  return value % SNARK_SCALAR_FIELD;
}

export function hashPair(left: bigint, right: bigint): bigint {
  const t = mod(toField(left) + mod(toField(right) * HASH_BETA) + HASH_C);
  const t2 = mod(t * t);
  const t4 = mod(t2 * t2);
  return mod(t4 * t);
}

export function deriveActionIds(batch: Omit<SettlementBatchPayload, "actionsRoot">): bigint[] {
  const ids: bigint[] = [];

  for (const action of batch.supplyCredits) {
    let h = hashPair(INTENT_SUPPLY, action.depositId);
    h = hashPair(h, BigInt(action.user));
    h = hashPair(h, BigInt(action.hubAsset));
    ids.push(hashPair(h, action.amount));
  }

  for (const action of batch.repayCredits) {
    let h = hashPair(INTENT_REPAY, action.depositId);
    h = hashPair(h, BigInt(action.user));
    h = hashPair(h, BigInt(action.hubAsset));
    ids.push(hashPair(h, action.amount));
  }

  for (const action of batch.borrowFinalizations) {
    let h = hashPair(INTENT_BORROW, BigInt(action.intentId));
    h = hashPair(h, BigInt(action.user));
    h = hashPair(h, BigInt(action.hubAsset));
    h = hashPair(h, action.amount);
    h = hashPair(h, action.fee);
    ids.push(hashPair(h, BigInt(action.relayer)));
  }

  for (const action of batch.withdrawFinalizations) {
    let h = hashPair(INTENT_WITHDRAW, BigInt(action.intentId));
    h = hashPair(h, BigInt(action.user));
    h = hashPair(h, BigInt(action.hubAsset));
    h = hashPair(h, action.amount);
    h = hashPair(h, action.fee);
    ids.push(hashPair(h, BigInt(action.relayer)));
  }

  if (ids.length > MAX_BATCH_ACTIONS) {
    throw new Error(`too many actions for proof root: ${ids.length} > ${MAX_BATCH_ACTIONS}`);
  }

  return ids;
}

export function computeActionsRoot(batch: Omit<SettlementBatchPayload, "actionsRoot">): `0x${string}` {
  const actionIds = deriveActionIds(batch);
  let state = hashPair(toField(batch.batchId), toField(batch.hubChainId));
  state = hashPair(state, toField(batch.spokeChainId));
  state = hashPair(state, BigInt(actionIds.length));

  for (const id of actionIds) {
    state = hashPair(state, id);
  }
  for (let i = actionIds.length; i < MAX_BATCH_ACTIONS; i++) {
    state = hashPair(state, 0n);
  }

  return numberToHex(state, { size: 32 });
}

function mod(value: bigint): bigint {
  const result = value % SNARK_SCALAR_FIELD;
  return result < 0n ? result + SNARK_SCALAR_FIELD : result;
}
