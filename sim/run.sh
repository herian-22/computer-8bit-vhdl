#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p sim

ghdl -a src/cpu/alu.vhd \
      src/mem/rom_128x8_sync.vhd \
      src/mem/rw_96x8_sync.vhd \
      src/mem/memory_system.vhd \
      src/cpu/data_path.vhd \
      src/cpu/control_unit.vhd \
      src/cpu/cpu.vhd \
      src/top/computer_top.vhd \
      tb/tb_computer.vhd

ghdl -e tb_computer

ghdl -r tb_computer --wave=sim/wave.ghw --stop-time=13us

if command -v gtkwave >/dev/null 2>&1; then
  gtkwave sim/wave.ghw &
fi
