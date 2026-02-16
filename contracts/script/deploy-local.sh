#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR/contracts"

forge build >/dev/null

cd "$ROOT_DIR"
node ./contracts/script/deploy-local.mjs
