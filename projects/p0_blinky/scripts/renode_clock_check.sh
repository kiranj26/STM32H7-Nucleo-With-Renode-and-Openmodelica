#!/usr/bin/env bash
# P0: measure which clocks Renode re-times from the firmware's RCC setup.
# Counts TIM2_CNT (PSC=0) and DWT_CYCCNT over 1 ms of VIRTUAL time, with and without the
# P0 firmware having run SystemClock_Config. Run in the devcontainer from the repo root:
#   bash projects/p0_blinky/scripts/renode_clock_check.sh
set -euo pipefail

EMPTY='mach create "m"
machine LoadPlatformDescription @platforms/cpus/stm32h743.repl'
BOOTED='include @projects/p0_blinky/renode/p0.resc
emulation RunFor "0.2"'
# RCC_APB1LENR.TIM2EN=1, TIM2_CR1.CEN=1, run 1 ms, read TIM2_CNT
TIM2='sysbus WriteDoubleWord 0x580244E8 0x1
sysbus WriteDoubleWord 0x40000000 0x1
emulation RunFor "0.001"
sysbus ReadDoubleWord 0x40000024'
# DEMCR.TRCENA=1, CYCCNT=0, DWT_CTRL.CYCCNTENA=1, run 1 ms, read CYCCNT
DWT='sysbus WriteDoubleWord 0xE000EDFC 0x01000000
sysbus WriteDoubleWord 0xE0001004 0x0
sysbus WriteDoubleWord 0xE0001000 0x1
emulation RunFor "0.001"
sysbus ReadDoubleWord 0xE0001004'

measure() { # measure <label> <setup> <probe> <board_MHz>
    local hex n
    hex=$(printf '%s\n%s\nquit\n' "$2" "$3" \
        | renode --console --disable-gui --plain --hide-log 2>&1 | tr -d '\r' \
        | grep -oE '^0x[0-9A-Fa-f]+' | tail -1)
    n=$((hex))
    printf '%-14s %14d %10d %10d\n' "$1" "$n" $((n / 1000)) "$4"
}

echo "case           counts_per_1ms  Renode_MHz  board_MHz"
measure "empty  TIM2" "$EMPTY" "$TIM2" 200
measure "booted TIM2" "$BOOTED" "$TIM2" 200
measure "empty  DWT" "$EMPTY" "$DWT" 400
measure "booted DWT" "$BOOTED" "$DWT" 400
