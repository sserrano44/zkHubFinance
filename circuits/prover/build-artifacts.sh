#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CIRCUIT_PATH="$ROOT_DIR/circuits/circom/SettlementBatchRoot.circom"
OUT_DIR="$ROOT_DIR/circuits/prover/artifacts"

if ! command -v circom >/dev/null 2>&1; then
  echo "circom not found in PATH"
  exit 1
fi

if ! command -v snarkjs >/dev/null 2>&1; then
  echo "snarkjs not found in PATH"
  exit 1
fi

mkdir -p "$OUT_DIR"

echo "[zk] compiling circuit"
circom "$CIRCUIT_PATH" --r1cs --wasm --sym -o "$OUT_DIR"

R1CS_PATH="$OUT_DIR/SettlementBatchRoot.r1cs"
WASM_DIR="$OUT_DIR/SettlementBatchRoot_js"
ZKEY_0="$OUT_DIR/SettlementBatchRoot_0000.zkey"
ZKEY_FINAL="$OUT_DIR/SettlementBatchRoot_final.zkey"
VK_PATH="$OUT_DIR/verification_key.json"
SOLIDITY_VERIFIER_PATH="$OUT_DIR/Groth16Verifier.generated.sol"

PTAU_PATH="${PTAU_PATH:-$OUT_DIR/pot12_final.ptau}"
if [[ ! -f "$PTAU_PATH" ]]; then
  echo "[zk] no PTAU found, generating local test PTAU ($PTAU_PATH)"
  snarkjs powersoftau new bn128 12 "$OUT_DIR/pot12_0000.ptau" -v
  # Keep artifact generation non-interactive across snarkjs versions.
  # Older versions (e.g. 0.7.x) do not support non-interactive contribute flags.
  PTAU_BEACON_HASH="${PTAU_BEACON_HASH:-0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef}"
  PTAU_BEACON_EXP="${PTAU_BEACON_EXP:-10}"
  snarkjs powersoftau beacon "$OUT_DIR/pot12_0000.ptau" "$OUT_DIR/pot12_beacon.ptau" "$PTAU_BEACON_HASH" "$PTAU_BEACON_EXP"
  snarkjs powersoftau prepare phase2 "$OUT_DIR/pot12_beacon.ptau" "$OUT_DIR/pot12_final.ptau"
fi

echo "[zk] running groth16 setup"
snarkjs groth16 setup "$R1CS_PATH" "$PTAU_PATH" "$ZKEY_0"
ZKEY_BEACON_HASH="${ZKEY_BEACON_HASH:-abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789}"
ZKEY_BEACON_EXP="${ZKEY_BEACON_EXP:-10}"
snarkjs zkey beacon "$ZKEY_0" "$ZKEY_FINAL" "$ZKEY_BEACON_HASH" "$ZKEY_BEACON_EXP"
snarkjs zkey export verificationkey "$ZKEY_FINAL" "$VK_PATH"
snarkjs zkey export solidityverifier "$ZKEY_FINAL" "$SOLIDITY_VERIFIER_PATH"

echo "[zk] artifacts ready"
echo "  - $R1CS_PATH"
echo "  - $WASM_DIR/SettlementBatchRoot.wasm"
echo "  - $ZKEY_FINAL"
echo "  - $VK_PATH"
echo "  - $SOLIDITY_VERIFIER_PATH"
