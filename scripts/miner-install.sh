#!/usr/bin/env bash
set -euo pipefail

DEFAULT_RIGEL_VERSION="1.22.3"
RIGEL_VERSION="${RIGEL_VERSION:-$DEFAULT_RIGEL_VERSION}"
INSTALL_DIR="${RIGEL_INSTALL_DIR:-/opt/rigel}"
ARCHIVE="rigel-${RIGEL_VERSION}-linux.tar.gz"
RELEASE_URL="https://github.com/rigelminer/rigel/releases/download/${RIGEL_VERSION}/${ARCHIVE}"

if [[ $EUID -eq 0 ]]; then
  echo "[!] Run this script as a non-root user with sudo privileges" >&2
  exit 1
fi

echo "[*] Installing dependencies"
sudo apt-get update -y
sudo apt-get install -y wget tar screen git jq bc

echo "[*] Preparing install directory at ${INSTALL_DIR}"
sudo mkdir -p "$INSTALL_DIR"
sudo chown "$USER":"$USER" "$INSTALL_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "[*] Downloading Rigel Miner ${RIGEL_VERSION}"
wget -q --show-progress -O "$TMP_DIR/$ARCHIVE" "$RELEASE_URL"

echo "[*] Extracting Rigel Miner"
tar -xzf "$TMP_DIR/$ARCHIVE" -C "$INSTALL_DIR" --strip-components=1

echo "[*] Rigel Miner installed to $INSTALL_DIR"
echo "[*] To start mining: ./scripts/miner-start.sh configs/rigel_rvn.json"
