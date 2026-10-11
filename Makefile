# H7 lab: the single command interface for developers and CI (see CLAUDE.md "Commands").
#   make <target> P=p0 [TAGS=smoke] [TARGET=renode] [BUILD_TYPE=Debug]
# Container-side targets run in the devcontainer; `make hw` runs only on the macOS host.

SHELL       := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

P          ?=
BUILD_TYPE ?= Debug
TAGS       ?=
TARGET     ?= renode

# P=p0  ->  fw/p0_blinky  ->  NAME=p0_blinky
FW_DIR    := $(if $(P),$(firstword $(wildcard fw/$(P)_*)),)
NAME      := $(notdir $(FW_DIR))
BUILD_DIR := build/fw/$(NAME)
ELF       := $(BUILD_DIR)/$(NAME).elf
ROBOT_OUT := $(CURDIR)/build/robot/$(P)

# make hw settings (override on the command line, e.g. HW_DESC=hw_retest)
HW_PORT    ?= $(firstword $(wildcard /dev/cu.usbmodem*))
HW_SECS    ?= 20
HW_DESC    ?= hw_hello
HW_RUN_DIR := projects/$(NAME)/results/$(shell date +%F)_$(HW_DESC)

# Fail early with a clear message instead of a confusing CMake error
define require_project
	@test -n "$(P)"      || { echo "error: set P, e.g. make $@ P=p0"; exit 2; }
	@test -n "$(FW_DIR)" || { echo "error: no folder matches fw/$(P)_*"; exit 2; }
endef

.PHONY: help doctor fw hw test sim fmu unit lint clean

help: ## List targets
	@grep -E '^[a-z]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-8s %s\n", $$1, $$2}'

doctor: ## Print all tool versions; fail if one is missing
	@tools/doctor.sh

fw: ## Build firmware into build/fw/<name>/ (.elf .bin .hex) and print its size (container only)
	@test -n "$${IN_DEVCONTAINER:-}" || { echo "error: make fw runs in the devcontainer (its ELF is canonical, see docs/dev-environment.md)"; exit 2; }
	$(require_project)
	cmake -S $(FW_DIR) -B $(BUILD_DIR) -G Ninja \
	      -DCMAKE_TOOLCHAIN_FILE=$(CURDIR)/$(FW_DIR)/cmake/gcc-arm-none-eabi.cmake \
	      -DCMAKE_BUILD_TYPE=$(BUILD_TYPE)
	cmake --build $(BUILD_DIR)
	arm-none-eabi-objcopy -O binary $(ELF) $(BUILD_DIR)/$(NAME).bin
	arm-none-eabi-objcopy -O ihex   $(ELF) $(BUILD_DIR)/$(NAME).hex
	arm-none-eabi-size $(ELF)

hw: ## Flash P and capture UART evidence into a dated results folder (macOS host only)
	@test -z "$${IN_DEVCONTAINER:-}" || { echo "error: make hw runs on the macOS host (no USB passthrough into the container)"; exit 2; }
	$(require_project)
	@test -f $(BUILD_DIR)/$(NAME).bin || { echo "error: no $(BUILD_DIR)/$(NAME).bin - run 'make fw P=$(P)' in the devcontainer first"; exit 2; }
	@test -n "$(HW_PORT)" || { echo "error: no /dev/cu.usbmodem* found - is the board plugged in?"; exit 2; }
	@test ! -e $(HW_RUN_DIR) || { echo "error: $(HW_RUN_DIR) already exists - results are never overwritten; pass HW_DESC=<new_name>"; exit 2; }
	st-flash --reset write $(BUILD_DIR)/$(NAME).bin 0x08000000
	mkdir -p $(HW_RUN_DIR)
	perl projects/$(NAME)/scripts/capture_uart.pl $(HW_PORT) 115200 $(HW_SECS) $(HW_RUN_DIR)/uart.log
	@sha=$$(shasum -a 256 $(BUILD_DIR)/$(NAME).bin | cut -d' ' -f1); \
	commit=$$(git rev-parse --short HEAD)$$(git diff --quiet || echo "-dirty"); \
	printf '{\n  "project": "%s",\n  "level": "HW",\n  "date": "%s",\n  "bin": "%s",\n  "bin_sha256": "%s",\n  "git_commit": "%s",\n  "port": "%s",\n  "baud": 115200,\n  "duration_s": %s\n}\n' \
	  "$(NAME)" "$$(date +%F)" "$(BUILD_DIR)/$(NAME).bin" "$$sha" "$$commit" "$(HW_PORT)" "$(HW_SECS)" \
	  > $(HW_RUN_DIR)/meta.json
	@echo "hw: $$(grep -c Hello $(HW_RUN_DIR)/uart.log) Hello lines -> $(HW_RUN_DIR)/"

test: ## Robot suite for P on Renode -> build/robot/pN/ (container; TAGS=smoke to filter)
	@test -n "$${IN_DEVCONTAINER:-}" || { echo "error: make test runs in the devcontainer (Renode + Robot live there)"; exit 2; }
	$(require_project)
	@test "$(TARGET)" = renode || { echo "error: TARGET=$(TARGET) not supported yet (P0 has renode only; mil/sil/hw come in P1+)"; exit 2; }
	@test -f $(ELF) || { echo "error: no $(ELF) - run 'make fw P=$(P)' first"; exit 2; }
	rm -rf $(ROBOT_OUT) && mkdir -p $(ROBOT_OUT)
	# renode-test writes its reports into the current directory, so run it from the output folder
	cd $(ROBOT_OUT) && renode-test $(CURDIR)/projects/$(NAME)/robot/*.robot \
	    $(if $(TAGS),--include $(TAGS)) --variable TARGET:$(TARGET)

sim: ## Simulate the project's models (.mos) and post-process -> build/sim/pN/ (container)
	@test -n "$${IN_DEVCONTAINER:-}" || { echo "error: make sim runs in the devcontainer (OpenModelica lives there)"; exit 2; }
	$(require_project)
	omc projects/$(NAME)/scripts/$(P).mos | tee build/sim-$(P).log
	@! grep -q '"Error\|\[.*Error' build/sim-$(P).log || { echo "error: omc reported errors (see build/sim-$(P).log)"; exit 1; }
	python projects/$(NAME)/scripts/rc_compare.py build/sim/$(P)

fmu: ## Export and validate the plant FMU (P1+)
	@echo "make fmu: no plant FMU before P1"; exit 2

unit: ## Host unit tests for fw/common/ctrl and tools/labkit (P1+)
	@echo "make unit: nothing to test before P1 (fw/common/ctrl, tools/labkit don't exist yet)"; exit 2

lint: ## ruff (Python) + clang-format (our C only, never CubeMX/HAL code) - check, don't modify (container)
	@test -n "$${IN_DEVCONTAINER:-}" || { echo "error: make lint runs in the devcontainer (pinned ruff/clang-format)"; exit 2; }
	ruff check projects tools
	ruff format --check projects tools
	clang-format --dry-run --Werror $(wildcard fw/*/app/*.[ch] fw/common/*/*.[ch])

clean: ## Remove build/
	rm -rf build
