import { computeActionsRoot } from "./hash";
export function buildBatch(batchId, hubChainId, spokeChainId, actions) {
    const supplyCredits = actions
        .filter((action) => action.kind === "supply")
        .map((a) => ({ depositId: a.depositId, user: a.user, hubAsset: a.hubAsset, amount: a.amount }));
    const repayCredits = actions
        .filter((action) => action.kind === "repay")
        .map((a) => ({ depositId: a.depositId, user: a.user, hubAsset: a.hubAsset, amount: a.amount }));
    const borrowFinalizations = actions
        .filter((action) => action.kind === "borrow")
        .map((a) => ({
        intentId: a.intentId,
        user: a.user,
        hubAsset: a.hubAsset,
        amount: a.amount,
        fee: a.fee,
        relayer: a.relayer
    }));
    const withdrawFinalizations = actions
        .filter((action) => action.kind === "withdraw")
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
    const batch = {
        ...batchCore,
        actionsRoot
    };
    return batch;
}
//# sourceMappingURL=batch.js.map