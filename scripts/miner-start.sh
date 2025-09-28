#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="${RIGEL_INSTALL_DIR:-/opt/rigel}"
CONFIG_PATH="${1:-configs/rigel_rvn.json}"

if [[ ! -x "$INSTALL_DIR/rigel" ]]; then
  echo "[!] Rigel binary not found at $INSTALL_DIR/rigel" >&2
  echo "[i] Run ./scripts/miner-install.sh first." >&2
  exit 1
fi

ABS_CONFIG="$REPO_ROOT/$CONFIG_PATH"
if [[ ! -f "$ABS_CONFIG" ]]; then
  echo "[!] Config file not found: $ABS_CONFIG" >&2
  exit 1
fi

echo "[*] Starting Rigel with config $ABS_CONFIG"
exec "$INSTALL_DIR/rigel" -c "$ABS_CONFIG"
