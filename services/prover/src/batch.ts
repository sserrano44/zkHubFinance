import type { QueuedAction, SettlementBatchPayload } from "./types";
import { computeActionsRoot } from "./hash";

export function buildBatch(batchId: bigint, hubChainId: bigint, spokeChainId: bigint, actions: QueuedAction[]) {
  const supplyCredits = actions
    .filter((action): action is Extract<QueuedAction, { kind: "supply" }> => action.kind === "supply")
    .map((a) => ({ depositId: a.depositId, user: a.user, hubAsset: a.hubAsset, amount: a.amount }));

  const repayCredits = actions
    .filter((action): action is Extract<QueuedAction, { kind: "repay" }> => action.kind === "repay")
    .map((a) => ({ depositId: a.depositId, user: a.user, hubAsset: a.hubAsset, amount: a.amount }));

  const borrowFinalizations = actions
    .filter((action): action is Extract<QueuedAction, { kind: "borrow" }> => action.kind === "borrow")
    .map((a) => ({
      intentId: a.intentId,
      user: a.user,
      hubAsset: a.hubAsset,
      amount: a.amount,
      fee: a.fee,
      relayer: a.relayer
    }));

  const withdrawFinalizations = actions
    .filter((action): action is Extract<QueuedAction, { kind: "withdraw" }> => action.kind === "withdraw")
    .map((a) => ({
      intentId: a.intentId,
      user: a.user,
      hubAsset: a.hubAsset,
      amount: a.amount,
      fee: a.fee,
      relayer: a.relayer
    }));

  const batchCore = {
    batchId,
    hubChainId,
    spokeChainId,
    supplyCredits,
    repayCredits,
    borrowFinalizations,
    withdrawFinalizations
  };
  const actionsRoot = computeActionsRoot(batchCore);

  const batch: SettlementBatchPayload = {
    ...batchCore,
    actionsRoot
  };

  return batch;
}
