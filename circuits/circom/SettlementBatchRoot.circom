pragma circom 2.1.9;

// Field-safe settlement root circuit.
// Public signals stay stable with on-chain verifier expectations:
// [batchId, hubChainId, spokeChainId, actionsRoot]
//
// Private witness:
// - actionCount
// - actionIds[50] (padded with zeros off-chain)
//
// The circuit recomputes the deterministic action root used by HubSettlement.

template HashPair() {
    signal input left;
    signal input right;
    signal output out;

    var BETA = 1315423911;
    var C = 11400714819323198485;

    signal t;
    t <== left + (right * BETA) + C;

    signal t2;
    signal t4;
    t2 <== t * t;
    t4 <== t2 * t2;
    out <== t4 * t;
}

template SettlementBatchRoot(maxActions) {
    signal input batchId;
    signal input hubChainId;
    signal input spokeChainId;
    signal input actionsRoot;

    signal input actionCount;
    signal input actionIds[maxActions];

    signal acc[maxActions + 4];
    component steps[maxActions];

    component start0 = HashPair();
    start0.left <== batchId;
    start0.right <== hubChainId;
    acc[0] <== start0.out;

    component start1 = HashPair();
    start1.left <== acc[0];
    start1.right <== spokeChainId;
    acc[1] <== start1.out;

    component start2 = HashPair();
    start2.left <== acc[1];
    start2.right <== actionCount;
    acc[2] <== start2.out;

    for (var i = 0; i < maxActions; i++) {
        steps[i] = HashPair();
        steps[i].left <== acc[i + 2];
        steps[i].right <== actionIds[i];
        acc[i + 3] <== steps[i].out;
    }

    acc[maxActions + 2] === actionsRoot;
}

component main { public [batchId, hubChainId, spokeChainId, actionsRoot] } = SettlementBatchRoot(50);
