#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_PATH="${1:-configs/rigel_rvn.json}"
IDLE_THRESHOLD="${IDLE_THRESHOLD:-10}"
CHECK_INTERVAL="${CHECK_INTERVAL:-60}"

if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "[!] nvidia-smi not available; idle detection requires NVIDIA drivers" >&2
  exit 1
fi

echo "[*] Idle monitor started (threshold: ${IDLE_THRESHOLD}% GPU util, interval: ${CHECK_INTERVAL}s)"

while true; do
  UTIL_AVG=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk '{sum+=$1} END { if (NR>0) printf "%.2f", sum/NR; else print 0 }')

  if [[ -z "$UTIL_AVG" ]]; then
    echo "[!] Unable to read GPU utilization"
    sleep "$CHECK_INTERVAL"
    continue
  fi

  if (( $(echo "$UTIL_AVG < $IDLE_THRESHOLD" | bc -l) )); then
    echo "[*] GPU idle (${UTIL_AVG}%), starting miner"
    "${REPO_ROOT}/scripts/miner-start.sh" "$CONFIG_PATH" || true
  else
    echo "[*] GPU busy (${UTIL_AVG}%), waiting"
    sleep "$CHECK_INTERVAL"
  fi
done
