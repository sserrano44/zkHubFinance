# ZK Settlement Circuits

This folder contains the Circom circuit and proof tooling for settlement batches.

## Circuit status
- `circom/SettlementBatchRoot.circom` is now a concrete field-safe circuit.
- Public signals remain stable with the hub verifier contract:
  1. `batchId`
  2. `hubChainId`
  3. `spokeChainId`
  4. `actionsRoot`
- The circuit recomputes the deterministic padded action-root hash from witness `actionIds[50]` and `actionCount`.

## On-chain compatibility
- `HubSettlement.computeActionsRoot` now returns a SNARK-field-safe root (`< SNARK_SCALAR_FIELD`) with fixed-width padding.
- `Verifier` still accepts `(bytes proof, uint256[] publicInputs)`; production mode delegates to a Groth16 verifier-compatible contract.

## Build artifacts
Use the helper script:

```bash
bash ./circuits/prover/build-artifacts.sh
```

It generates:
- `circuits/prover/artifacts/SettlementBatchRoot.r1cs`
- `circuits/prover/artifacts/SettlementBatchRoot_js/SettlementBatchRoot.wasm`
- `circuits/prover/artifacts/SettlementBatchRoot_final.zkey`
- `circuits/prover/artifacts/verification_key.json`
- `circuits/prover/artifacts/Groth16Verifier.generated.sol`
