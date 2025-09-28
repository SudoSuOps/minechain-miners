#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_PATH="${1:-configs/rigel_rvn.json}"
SLEEP_SECONDS="${WATCHDOG_SLEEP:-10}"

echo "[*] Launching Rigel watchdog (config: $CONFIG_PATH, retry delay: ${SLEEP_SECONDS}s)"

while true; do
  "${REPO_ROOT}/scripts/miner-start.sh" "$CONFIG_PATH" || true
  echo "[!] Miner exited, restarting in ${SLEEP_SECONDS}s"
  sleep "$SLEEP_SECONDS"
done
