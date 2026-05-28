# 8-bit Computer System (VHDL)

Implementasi komputer 8-bit sesuai **Chapter 13** dari buku:
> *Introduction to Logic Circuits & Logic Design with VHDL* (2019)  
> Brock J. LaMeres

## Arsitektur

**Von Neumann Architecture** dengan memory map:
- **Program ROM**: `0x00 - 0x7F` (128 bytes)
- **Data RAM**: `0x80 - 0xDF` (96 bytes)
- **Output Ports**: `0xE0 - 0xEF` (16 ports)
- **Input Ports**: `0xF0 - 0xFF` (16 ports)

### Blok Diagram

```
┌─────────────────────────────────────────────────┐
│              COMPUTER_TOP                       │
│  ┌──────────────┐         ┌─────────────────┐  │
│  │     CPU      │◄───────►│ MEMORY_SYSTEM   │  │
│  │              │         │                 │  │
│  │ ┌──────────┐ │         │ ┌─────────────┐ │  │
│  │ │ Control  │ │         │ │   ROM       │ │  │
│  │ │  Unit    │ │         │ │  (Program)  │ │  │
│  │ │  (FSM)   │ │         │ └─────────────┘ │  │
│  │ └──────────┘ │         │ ┌─────────────┐ │  │
│  │              │         │ │   RAM       │ │  │
│  │ ┌──────────┐ │         │ │   (Data)    │ │  │
│  │ │   Data   │ │         │ └─────────────┘ │  │
│  │ │   Path   │ │         │ ┌─────────────┐ │  │
│  │ │          │ │         │ │  I/O Ports  │ │  │
│  │ │  ┌─────┐ │ │         │ └─────────────┘ │  │
│  │ │  │ ALU │ │ │         │                 │  │
│  │ │  └─────┘ │ │         └─────────────────┘  │
│  │ │  PC,A,B  │ │                               │
│  │ │  IR,MAR  │ │                               │
│  │ └──────────┘ │                               │
│  └──────────────┘                               │
└─────────────────────────────────────────────────┘
```

## Instruction Set

| Opcode | Mnemonic | Operand | Description |
|--------|----------|---------|-------------|
| `0x86` | LDA_IMM  | data    | Load A immediate |
| `0x87` | LDA_DIR  | addr    | Load A direct |
| `0x88` | LDB_IMM  | data    | Load B immediate |
| `0x89` | LDB_DIR  | addr    | Load B direct |
| `0x96` | STA_DIR  | addr    | Store A direct |
| `0x97` | STB_DIR  | addr    | Store B direct |
| `0x42` | ADD_AB   | -       | A = A + B |
| `0x43` | SUB_AB   | -       | A = A - B |
| `0x44` | AND_AB   | -       | A = A & B |
| `0x45` | OR_AB    | -       | A = A \| B |
| `0x46` | INCA     | -       | A = A + 1 |
| `0x47` | INCB     | -       | B = B + 1 |
| `0x48` | DECA     | -       | A = A - 1 |
| `0x49` | DECB     | -       | B = B - 1 |
| `0x20` | BRA      | addr    | Branch always |
| `0x21` | BMI      | addr    | Branch if N=1 |
| `0x22` | BPL      | addr    | Branch if N=0 |
| `0x23` | BEQ      | addr    | Branch if Z=1 |
| `0x24` | BNE      | addr    | Branch if Z=0 |
| `0x25` | BVS      | addr    | Branch if V=1 |
| `0x26` | BVC      | addr    | Branch if V=0 |
| `0x27` | BCS      | addr    | Branch if C=1 |
| `0x28` | BCC      | addr    | Branch if C=0 |

### Status Flags (CCR)
- **N** (Negative): bit 7 of result
- **Z** (Zero): result = 0
- **V** (Overflow): signed overflow
- **C** (Carry): unsigned carry/borrow

## Project Structure

```
.
├── src/
│   ├── cpu/
│   │   ├── alu.vhd              # Arithmetic Logic Unit
│   │   ├── data_path.vhd        # Registers, buses, ALU integration
│   │   ├── control_unit.vhd     # FSM (fetch/decode/execute)
│   │   └── cpu.vhd              # CPU top (control + datapath)
│   ├── mem/
│   │   ├── rom_128x8_sync.vhd   # Program ROM with test program
│   │   ├── rw_96x8_sync.vhd     # Data RAM
│   │   └── memory_system.vhd    # Memory + I/O ports + MUX
│   └── top/
│       └── computer_top.vhd     # Top level (CPU + Memory)
├── tb/
│   └── tb_computer.vhd          # Testbench with assertions
├── sim/
│   ├── run.sh                   # Build/run script (bash)
│   ├── run.bat                  # Build/run script (Windows)
│   └── wave.ghw                 # Waveform output
└── README.md
```

## Test Program

Program di ROM (`src/mem/rom_128x8_sync.vhd`) test semua instruksi:

1. **LDA_IMM/LDB_IMM/ADD_AB**: `0x05 + 0x03 = 0x08` → port_out_00
2. **ADD overflow**: `0xFF + 0x01 = 0x00` (Z=1, C=1) → port_out_01
3. **BEQ branch**: Branch jika Z=1 (skip 0xAA write)
4. **Branch target**: Write `0x55` → port_out_03
5. **SUB_AB**: `0x0A - 0x03 = 0x07` → port_out_04
6. **AND_AB**: `0x0F & 0xF0 = 0x00` → port_out_05
7. **OR_AB**: `0x0F | 0xF0 = 0xFF` → port_out_06
8. **INCA**: `0x7F + 1 = 0x80` → port_out_07
9. **DECA**: `0x01 - 1 = 0x00` → port_out_08
10. **BRA loop**: Jump back ke start

## Build & Run

### Requirements
- **GHDL** (sudah installed di `C:\Program Files (x86)\Ghdl\Bin\`)
- **GTKWave** (sudah installed di `C:\msys64\ucrt64\bin\`)

### Quick Start

**Windows (CMD/PowerShell):**
```cmd
cd sim
run.bat
```

**MSYS2/Git Bash:**
```bash
cd sim
bash run.sh
```

### Manual Build

```bash
# Analyze
ghdl -a src/cpu/alu.vhd \
      src/mem/rom_128x8_sync.vhd \
      src/mem/rw_96x8_sync.vhd \
      src/mem/memory_system.vhd \
      src/cpu/data_path.vhd \
      src/cpu/control_unit.vhd \
      src/cpu/cpu.vhd \
      src/top/computer_top.vhd \
      tb/tb_computer.vhd

# Elaborate
ghdl -e tb_computer

# Run simulation
ghdl -r tb_computer --wave=sim/wave.ghw --stop-time=13us

# View waveform
gtkwave sim/wave.ghw
```

## Expected Output

```
===================================================
Test results (from output ports):
===================================================
PASS Test1 LDA_IMM/LDB_IMM/ADD_AB -> port_out_00 = 0x08
PASS Test2 ADD overflow -> port_out_01 = 0x00 (Z=1)
PASS Test3 BEQ branch taken (port_out_02 untouched)
PASS Test3b BEQ target reached -> port_out_03 = 0x55
PASS Test4 SUB_AB -> port_out_04 = 0x07
PASS Test5 AND_AB -> port_out_05 = 0x00
PASS Test6 OR_AB -> port_out_06 = 0xFF
PASS Test7 INCA -> port_out_07 = 0x80
PASS Test8 DECA -> port_out_08 = 0x00
===================================================
ALL TESTS COMPLETE
===================================================
```

## Waveform Signals (GTKWave)

Signals penting untuk debug:
- `clock`, `reset`
- `DUT/CPU_INST/CU/current_state` - FSM state
- `DUT/CPU_INST/DP/PC` - Program Counter
- `DUT/CPU_INST/DP/IR_reg` - Instruction Register
- `DUT/CPU_INST/DP/A`, `DUT/CPU_INST/DP/B` - Registers
- `DUT/CPU_INST/DP/CCR` - Status flags (NZVC)
- `DUT/MEM_INST/address` - Address bus
- `DUT/MEM_INST/port_out_00` sampai `port_out_15` - Output ports

## Modifikasi Program

Edit `src/mem/rom_128x8_sync.vhd`, bagian `constant ROM : rom_type := (...)`:

```vhdl
constant ROM : rom_type := (
  0  => LDA_IMM,
  1  => x"42",      -- Load A = 0x42
  2  => STA_DIR,
  3  => x"E0",      -- Store ke port_out_00
  4  => BRA,
  5  => x"00",      -- Loop
  others => x"00"
);
```

Compile ulang dengan `run.bat` atau `run.sh`.

## Referensi

- Buku: Chapter 13 (p. 439-480)
- Example 13.8: Top-level block diagram
- Example 13.9: Instruction set
- Example 13.11: CPU block diagram
- Example 13.12-13.24: Detailed instruction execution

## License

Educational project - sesuai buku LaMeres (2019).
# computer-8bit-vhdl
