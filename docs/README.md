# MineChain Miners (Rigel) — Git-Ops Guide

Run your **Rigel miner** like application code: versioned configs, reproducible scripts, and clean Git-Ops rollouts across rigs.

> Tested on Ubuntu 22.04 / 24.04 with NVIDIA 580-open drivers and CUDA 13.x. Assumes NVIDIA drivers are present and `nvidia-smi` works.

---

## 📦 Repo Layout

| Path | Description |
| --- | --- |
| `configs/rigel_rvn.json` | Ravencoin (KawPoW) solo/stratum template |
| `configs/rigel_dual.json` | Dual/triple mining (ETHW + ZIL example) |
| `configs/zil.json` | Zilliqa-only profile |
| `scripts/miner-install.sh` | Installs Rigel and runtime dependencies |
| `scripts/miner-start.sh` | Launches Rigel with a selected config |
| `scripts/miner-watchdog.sh` | Auto-restarts Rigel on crash/exit |
| `scripts/miner-idle.sh` | Runs Rigel only when GPUs are idle |
| `docs/README.md` | This Git-Ops guide |
| `Makefile` | Shortcut targets (`install`, `watchdog`, `idle`, `update`) |

---

## 🚀 Quick Start (Single Rig)

```bash
# 1) clone (SSH recommended)
git clone git@github.com:<YOUR_ORG_OR_USER>/minechain-miners.git
cd minechain-miners

# 2) install Rigel + deps
./scripts/miner-install.sh

# 3) edit your config (wallet, pool, worker tag)
nano configs/rigel_rvn.json

# 4) launch with watchdog in a screen session (auto restarts on crash)


# (optional) view miner logs
screen -r miner   # reattach
Ctrl+a then d     # detach without killing
```

To update and restart:

```bash
git pull origin main
screen -S miner -X quit
screen -S miner ./scripts/miner-watchdog.sh
```

---

## ✅ Prerequisites

* NVIDIA driver + CUDA runtime already installed (validated with `nvidia-smi`).
* Internet egress to your mining pool(s).
* Packages used by the scripts: `screen`, `git`, `jq`, `wget`, `bc` (installed automatically by `miner-install.sh`; install manually with `sudo apt-get install -y screen jq wget bc` if needed).
* If you see `NoPermission` when applying OC, it’s driver policy (CoolBits). Mining works without OC—tune later.

---

## ⚙️ Configure Rigel

Edit the config that matches your strategy (example assumes Ravencoin):

```bash
nano configs/rigel_rvn.json
```

Update:

* Wallet address / payout string
* Pool URL + port (match pool docs)
* Worker name / rig tag
* Optional device list (`"0,1,2"` or `"all"`), intensity, etc.

Example `configs/rigel_rvn.json`:

```json
{
  "algo": "kawpow",
  "url": "stratum+tcp://solo-rvn.2miners.com:7070",
  "user": "RVN_WALLET_ADDRESS.WORKER_NAME",
  "pass": "x",
  "api": "127.0.0.1:4068",
  "watchdog": true,
  "log": "logs/rigel_rvn.log",
  "devices": "all",
  "retries": 3,
  "retry-pause": 10
}
```

Maintain additional configs per coin (`configs/zil.json`, `configs/rigel_dual.json`, etc.).

---

## ▶️ Start, Watchdog, and Idle Modes

| Mode | Command | Notes |
| --- | --- | --- |
| One-shot | `./scripts/miner-start.sh` | Runs once; exits on failure |
| Watchdog | `screen -S miner ./scripts/miner-watchdog.sh` | Auto-restarts (10 s backoff) inside `screen` |
| Idle mining | `screen -S idle ./scripts/miner-idle.sh` | Launches when average GPU util < `10%` (tunable) |

Idle mode polls `nvidia-smi` every 60 s. Adjust the threshold by editing the script or exporting `IDLE_THRESHOLD`.

---

## 🛠️ Rigel Miner Feature Highlights

* Linux and Windows builds with TUI and HTTP API
* Failover pool chains (repeat `-o/--url` per endpoint)
* Temperature, power, and fan telemetry plus automated limits
* Integrated OC controls (`--cclock`, `--mclock`, `--pl`, `--lock-*`)
* ZIL-specific tuning toggles and countdown
* Watchdog, log rotation, dual/triple mining

---

## 📋 Rigel CLI Cheat Sheet

* `-a`, `--algorithm` / `algo1+algo2+zil` – select algorithms (dual/triple mining)
* `-o`, `--url` – set pool URL(s); prepend `[index]` for secondary algos
* `-u`, `--username`, `-w`, `--worker`, `-p`, `--password` – authentication strings (support `[index]`)
* `-d`, `--devices`, `--list-devices` – GPU selection and enumeration
* `--temp-limit`, `--fan-control`, `--pl` – thermal/power management
* `--cclock`, `--mclock`, `--lock-*`, `--dual-mode` – overclock tuning
* `--zil`, `--zil-cache-dag`, `--zil-countdown` – ZIL behaviour toggles
* `--log-file`, `--stats-interval`, `--log-network` – logging instrumentation
* `--api-bind` – expose HTTP API

Refer to <https://rigelminer.com> for the full flag matrix and supported algorithms.

---

## 🔁 Update via Git-Ops

**Controller (edit configs/scripts):**

```bash
git add -A
git commit -m "Tune kawpow, new worker names"
git push origin main
```

**On each rig:**

```bash
cd ~/minechain-miners
git pull origin main
screen -S miner -X quit || true
screen -S miner ./scripts/miner-watchdog.sh
```

Makefile shortcuts:

```bash
make update
make watchdog
```

### Fleet Rollout (Optional)

```bash
for H in rig1 rig2 rig3; do
  ssh "$H" "git clone git@github.com:<YOUR_ORG_OR_USER>/minechain-miners.git || true && \
             cd minechain-miners && git pull && \
             ./scripts/miner-install.sh && \
             screen -S miner -X quit || true && \
             screen -S miner ./scripts/miner-watchdog.sh"
done
```

Wire into Ansible for hands-free fleet updates (git pull + restart tasks).

---

## 🔧 Autostart on Boot (systemd)

`/etc/systemd/system/minechain-miner.service`:

```ini
[Unit]
Description=MineChain Miner Watchdog
After=network-online.target
Wants=network-online.target

[Service]
User=<your_user>
WorkingDirectory=/home/<your_user>/minechain-miners
ExecStart=/usr/bin/screen -DmS miner /home/<your_user>/minechain-miners/scripts/miner-watchdog.sh
ExecStop=/usr/bin/screen -S miner -X quit
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable + start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable minechain-miner
sudo systemctl start minechain-miner
sudo systemctl status minechain-miner
```

Swap `miner-watchdog.sh` for `miner-idle.sh` to boot into idle-only mode.

---

## 🧰 Makefile Cheats

```make
make install     # runs scripts/miner-install.sh
make start       # screen -S miner ./scripts/miner-start.sh
make watchdog    # screen -S miner ./scripts/miner-watchdog.sh
make idle        # screen -S idle  ./scripts/miner-idle.sh
make update      # git pull origin main
```

---

## 🖧 Logs & Health

* Log path comes from your JSON (`"log": "logs/rigel_rvn.log"`). View live with `tail -f logs/rigel_rvn.log`.
* HTTP API (if enabled via `api`/`--api-bind`): `http://127.0.0.1:4068` for miner status.

---

## 🩺 Troubleshooting

* `screen`, `bc`, or `jq` missing → rerun `./scripts/miner-install.sh` or install manually.
* `NoPermission` on OC → driver policy; ignore and tune later.
* Miner exits instantly → verify pool URL, wallet syntax, firewall/NAT, and algorithm.
* Rejected shares / low hashrate → check algo, pool region, intensity settings.
* Idle mode never starts → ensure `nvidia-smi` works; lower `IDLE_THRESHOLD`.

---

## 🔐 Security & Secrets

* Keep private wallets/configs in private repositories.
* Do not store seed phrases or keys in Git.
* Optional: template configs with environment variables (`${RVN_WALLET}`) via `envsubst` or pass wallet/worker via CLI overrides at runtime.

---

## 📎 Appendix — Example Dual Config

```json
{
  "algo": "kawpow",
  "url": "stratum+tcp://POOL_A:PORT_A",
  "user": "RVN_WALLET.WORKER",
  "pass": "x",
  "dual-algo": "zil",
  "dual-url": "stratum+tcp://POOL_ZIL:PORT_ZIL",
  "dual-user": "ZIL_WALLET.WORKER",
  "dual-pass": "x",
  "watchdog": true,
  "api": "127.0.0.1:4068",
  "log": "logs/rigel_dual.log",
  "devices": "all"
}
```

---

## ✅ Summary

* Install: `./scripts/miner-install.sh`
* Configure: edit `configs/rigel_rvn.json`
* Run watchdog: `screen -S miner ./scripts/miner-watchdog.sh`
* Idle mining: `screen -S idle ./scripts/miner-idle.sh`
* Update: `git pull` + restart screen session or `make update && make watchdog`
* Autostart: systemd service pointing at the watchdog/idle script

Happy hashing, fren. 🐈‍⬛⚡

---

## 🔗 Upstream Resources

* Official docs: <https://rigelminer.com>
* Discord: <https://discord.gg/zKTgcGgc6k>
* BitcoinTalk: <https://bitcointalk.org/index.php?topic=5424675.0>