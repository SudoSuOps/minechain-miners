REPO_ROOT := $(shell pwd)
INSTALL_SCRIPT := $(REPO_ROOT)/scripts/miner-install.sh
START_SCRIPT := $(REPO_ROOT)/scripts/miner-start.sh
WATCHDOG_SCRIPT := $(REPO_ROOT)/scripts/miner-watchdog.sh
IDLE_SCRIPT := $(REPO_ROOT)/scripts/miner-idle.sh
DEFAULT_CONFIG := configs/rigel_rvn.json

.PHONY: install start watchdog idle update

install:
	@chmod +x $(INSTALL_SCRIPT)
	$(INSTALL_SCRIPT)

start:
	@chmod +x $(START_SCRIPT)
	screen -S miner $(START_SCRIPT) $(DEFAULT_CONFIG)

watchdog:
	@chmod +x $(WATCHDOG_SCRIPT)
	screen -S miner $(WATCHDOG_SCRIPT) $(DEFAULT_CONFIG)

idle:
	@chmod +x $(IDLE_SCRIPT)
	screen -S idle $(IDLE_SCRIPT) $(DEFAULT_CONFIG)

update:
	@git pull origin main
