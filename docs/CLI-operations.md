# Minechain Terminal Operations Guide (Linux)

Command-line workflows for deploying, operating, and maintaining Minechain GPU miners on Linux-only fleets.

## Baseline Assumptions

* Ubuntu 22.04/24.04 hosts with sudo access and NVIDIA drivers (`nvidia-smi` works).
* Repos pulled via SSH (`git@github.com:SudoSuOps/minechain-miners.git`).
* Shell examples assume a non-root operator using `bash` with passwordless sudo.

## Environment Prep

```bash
# Ensure baseline tooling
sudo apt-get update -y
sudo apt-get install -y git screen jq wget bc curl ansible sshpass

# Optional: persist locale + editor preferences
sudo update-alternatives --config editor
```

Verify GPU visibility:

```bash
nvidia-smi
```

## Repository Workflows

```bash
# Clone once per rig
git clone git@github.com:SudoSuOps/minechain-miners.git
cd minechain-miners

# Fetch latest
git pull origin main

# View repo status
git status -sb

# Inspect history
git log --oneline --graph -10
```

### Authoring Changes (controller)

```bash
git checkout -b feature/tune-kawpow
vim configs/rigel_rvn.json
git diff
git add configs/rigel_rvn.json
git commit -m "Tune KawPoW intensity for rig fleet"
git push -u origin feature/tune-kawpow
```

Merge via PR or fast-forward merge on `main` before rolling changes to rigs.

## Rigel Installation & Updates

Install or upgrade the miner stack:

```bash
./scripts/miner-install.sh               # Default version/location
RIGEL_VERSION=1.23.0 ./scripts/miner-install.sh
RIGEL_INSTALL_DIR=/opt/rigel ./scripts/miner-install.sh
```

Confirm binary:

```bash
ls -lh /opt/rigel/rigel
/opt/rigel/rigel --version
```

## Configuration Editing

```bash
cp configs/rigel_rvn.json configs/rigel_rvn.prod.json
nano configs/rigel_rvn.prod.json

# Validate JSON structure
jq empty configs/rigel_rvn.prod.json
```

## Miner Lifecycle Commands

### Screen Sessions

```bash
# Watchdog loop
screen -S miner ./scripts/miner-watchdog.sh [configs/<profile>.json]

# Idle-only loop
screen -S idle ./scripts/miner-idle.sh [configs/<profile>.json]

# Attach / detach
screen -r miner
# Detach safely (inside screen): Ctrl+a then d

# Terminate
screen -S miner -X quit
```

### Quick Launch Without Screen

```bash
./scripts/miner-start.sh configs/rigel_rvn.json
```

## Systemd Operations

```bash
sudo systemctl daemon-reload
sudo systemctl enable minechain-miner
sudo systemctl start minechain-miner
sudo systemctl status minechain-miner
sudo journalctl -u minechain-miner -f
```

Swap the service ExecStart to `scripts/miner-idle.sh` when needed and reload.

## Logging & Telemetry

```bash
# Tail miner logs
tail -f logs/rigel_rvn.log

# Follow driver events
sudo journalctl -u nvidia-persistenced -f

# Query Rigel HTTP API
curl -s http://127.0.0.1:4068/summary | jq
curl -s http://127.0.0.1:4068/workers | jq
```

### GPU & System Metrics

```bash
watch -n 5 nvidia-smi
sudo nvidia-smi topo -m
watch -n 5 sensors
```

## Fleet Automation

### SSH Fan-Out

```bash
for H in rig1 rig2 rig3; do
  ssh "$H" "cd minechain-miners && git pull && \
             screen -S miner -X quit || true && \
             screen -S miner ./scripts/miner-watchdog.sh"
done
```

### Ansible Playbook Invocation

```bash
ansible-playbook -i inventories/miners.ini playbooks/update-miners.yml
```

Example ad-hoc command:

```bash
ansible miners -i inventories/miners.ini -m shell \
  -a "cd ~/minechain-miners && git pull && screen -S miner -X quit || true && screen -S miner ./scripts/miner-watchdog.sh"
```

## Diagnostics & Troubleshooting

```bash
# Check process tree
ps -eo pid,ppid,cmd | grep rigel

# Inspect system load
htop
nvtop

# Validate network reachability
nc -zv rvn.pool.example 6060
curl -sv --connect-timeout 5 stratum+tcp://rvn.pool.example:6060

# GPU health
nvidia-smi dmon -s pucvmt -d 5

# Kernel logs
dmesg | tail -n 50
```

Resetting failed watchdog loops:

```bash
screen -S miner -X quit
sleep 5
screen -S miner ./scripts/miner-watchdog.sh configs/rigel_rvn.json
```

## Security Hardening Commands

```bash
# Disable password SSH logins
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl reload sshd

# Configure UFW to permit SSH only from controller
sudo ufw allow from 192.168.10.5 to any port 22 proto tcp
sudo ufw enable
sudo ufw status verbose

# Rotate SSH keys
ssh-keygen -t ed25519 -f ~/.ssh/minechain_ed25519
ssh-copy-id -i ~/.ssh/minechain_ed25519.pub user@rig1
```

## Backup & Recovery

```bash
# Archive configs and logs
tar -czf miner_backup_$(date +%F).tar.gz configs logs Makefile docs

# Restore from archive
tar -xzf miner_backup_2024-09-28.tar.gz -C ~/minechain-miners
```

## Reference Checks

```bash
# Current Rigel release
curl -s https://api.github.com/repos/rigelminer/rigel/releases/latest | jq -r '.tag_name'

# Validate JSON for all profiles
find configs -type f -name '*.json' -exec jq empty {} +

# List active screen sessions
screen -ls
```

## Operational Runbook Template

```
1. git pull origin main
2. Validate configs with jq
3. Restart watchdog (screen -S miner -X quit && screen -S miner ./scripts/miner-watchdog.sh)
4. Tail logs for 60 seconds
5. Check Rigel API summary
6. Confirm pool dashboard reflects expected hashrate
```

Document deviations in a shared ops log (e.g., `/var/log/minechain/ops-journal.md`).

---

All commands are Linux native—no Windows tooling required.
