# Analisa Kesesuaian dengan Chapter 13 Buku

## 1. MEMORY MAP (Buku p.454, Example 13.1)

### Buku:
```
0x00 - 0x7F  : Program ROM (128 bytes)
0x80 - 0xDF  : Data RAM (96 bytes)
0xE0 - 0xEF  : Output Ports (16 ports)
0xF0 - 0xFF  : Input Ports (16 ports)
```

### Project:
✅ **SESUAI**
- ROM: `src/mem/rom_128x8_sync.vhd` → address 0-127
- RAM: `src/mem/rw_96x8_sync.vhd` → address 128-223
- Output: `src/mem/memory_system.vhd` → address 0xE0-0xEF (16 ports)
- Input: `src/mem/memory_system.vhd` → address 0xF0-0xFF (16 ports)

---

## 2. INSTRUCTION SET (Buku p.455, Example 13.9)

### Buku Opcodes:
```
LDA_IMM: 0x86    LDA_DIR: 0x87
LDB_IMM: 0x88    LDB_DIR: 0x89
STA_DIR: 0x96    STB_DIR: 0x97
ADD_AB:  0x42    SUB_AB:  0x43
AND_AB:  0x44    OR_AB:   0x45
INCA:    0x46    INCB:    0x47
DECA:    0x48    DECB:    0x49
BRA:     0x20    BMI:     0x21
BPL:     0x22    BEQ:     0x23
BNE:     0x24    BVS:     0x25
BVC:     0x26    BCS:     0x27
BCC:     0x28
```

### Project:
✅ **SESUAI PERSIS**
- `src/cpu/control_unit.vhd` line 24-45: semua opcode sama
- `src/mem/rom_128x8_sync.vhd` line 8-29: semua opcode sama
- Addressing modes: IMM, DIR, INH (inherent) ✅

---

## 3. CPU ARCHITECTURE (Buku p.460, Example 13.11)

### Buku Blok:
```
┌─────────────────────────────────────┐
│ CPU                                 │
│ ┌──────────────┐  ┌──────────────┐ │
│ │ Control Unit │  │  Data Path   │ │
│ │   (FSM)      │  │              │ │
│ │              │  │ ┌──────────┐ │ │
│ │              │  │ │   ALU    │ │ │
│ │              │  │ └──────────┘ │ │
│ │              │  │ PC, A, B, IR │ │
│ │              │  │ MAR, CCR     │ │
│ └──────────────┘  └──────────────┘ │
└─────────────────────────────────────┘
```

### Project:
✅ **SESUAI**
- `src/cpu/control_unit.vhd` → FSM (fetch/decode/execute)
- `src/cpu/data_path.vhd` → registers + buses
- `src/cpu/alu.vhd` → ALU
- `src/cpu/cpu.vhd` → top CPU (control + datapath)

---

## 4. DATA PATH (Buku p.461, Example 13.11)

### Buku Registers:
- PC (Program Counter)
- IR (Instruction Register)
- MAR (Memory Address Register)
- A, B (General Purpose)
- CCR (Condition Code Register: NZVC)

### Project:
✅ **SESUAI PERSIS**
- `src/cpu/data_path.vhd`:
  - PC: line 108-120
  - IR: line 82-92
  - MAR: line 94-106
  - A, B: line 122-145
  - CCR: line 147-158

### Buku Buses:
- Bus1: output dari PC, A, B → to_memory
- Bus2: input ke IR, MAR, PC, A, B ← from_memory, ALU

### Project:
✅ **SESUAI PERSIS**
- Bus1 MUX: line 70-77 (select PC/A/B)
- Bus2 MUX: line 60-68 (select ALU/Bus1/from_memory)

---

## 5. ALU (Buku p.462, Example 13.11)

### Buku Operations:
- ADD (0x42): A + B, set NZVC
- SUB (0x43): A - B, set NZVC
- AND (0x44): A & B, set NZ
- OR (0x45): A | B, set NZ
- INCA (0x46): A + 1, set NZVC
- INCB (0x47): B + 1, set NZVC
- DECA (0x48): A - 1, set NZVC
- DECB (0x49): B - 1, set NZVC

### Project:
✅ **SESUAI PERSIS**
- `src/cpu/alu.vhd`:
  - ADD: line 30-48
  - SUB: line 50-68
  - AND: line 70-77
  - OR: line 79-86
  - INCA: line 88-101
  - INCB: line 103-116
  - DECA: line 118-131
  - DECB: line 133-146

### Flags (NZVC):
- N (Negative): bit 7 of result
- Z (Zero): result = 0
- V (Overflow): signed overflow
- C (Carry): unsigned carry

### Project:
✅ **SESUAI PERSIS**
- Semua flag dihitung per operasi
- Format: NZVC (4-bit)

---

## 6. CONTROL UNIT FSM (Buku p.464, Example 13.12-13.24)

### Buku States:
```
Fetch:
  S_FETCH_0 → S_FETCH_1 → S_FETCH_2 → S_DECODE_3

Decode:
  S_DECODE_3 → (select instruction path)

Execute (contoh):
  LDA_IMM: S_LDA_IMM_4 → S_LDA_IMM_5 → S_LDA_IMM_6 → S_FETCH_0
  LDA_DIR: S_LDA_DIR_4 → ... → S_LDA_DIR_8 → S_FETCH_0
  ADD_AB:  S_ADD_AB_4 → S_FETCH_0
  BRA:     S_BRA_4 → S_BRA_5 → S_BRA_6 → S_FETCH_0
  BEQ:     S_BEQ_4 → S_BEQ_5 → S_BEQ_6 → S_BEQ_7 (taken/not taken)
```

### Project:
✅ **SESUAI PERSIS**
- `src/cpu/control_unit.vhd`:
  - Fetch states: line 73-85
  - Decode state: line 87-127
  - LDA_IMM: line 129-135
  - LDA_DIR: line 137-151
  - LDB_IMM: line 153-159
  - LDB_DIR: line 161-175
  - STA_DIR: line 177-189
  - STB_DIR: line 191-203
  - Data manipulation: line 205-247
  - BRA: line 249-259
  - Conditional branches: line 261-273

---

## 7. MEMORY SYSTEM (Buku p.456, Example 13.10)

### Buku Blok:
```
ROM (0x00-0x7F)
RAM (0x80-0xDF)
Output Ports (0xE0-0xEF)
Input Ports (0xF0-0xFF)
MUX → data_out
```

### Project:
✅ **SESUAI PERSIS**
- `src/mem/memory_system.vhd`:
  - ROM instantiation: line 56-63
  - RAM instantiation: line 65-73
  - Output ports: line 75-267 (16 ports)
  - Input MUX: line 269-305

---

## 8. PROGRAM MEMORY (Buku p.456, Example 13.3.3.1)

### Buku Contoh Program:
```
Addr  Instr   Operand  Description
0x00  LDA_IMM 0xAA     Load A = 0xAA
0x02  STA_DIR 0xE0     Store A to port_out_00
0x04  BRA     0x00     Branch to 0x00 (loop)
```

### Project:
✅ **SESUAI + EXTENDED**
- `src/mem/rom_128x8_sync.vhd`:
  - Test 1: LDA_IMM + LDB_IMM + ADD_AB + STA_DIR (addr 0-6)
  - Test 2: ADD overflow (addr 7-13)
  - Test 3: BEQ branch (addr 14-25)
  - Test 4-8: SUB, AND, OR, INCA, DECA (addr 26-56)
  - Loop: BRA (addr 57-58)

---

## 9. INSTRUCTION EXECUTION (Buku p.466-479)

### Buku Contoh: LDA_IMM (Example 13.12)
```
S_FETCH_0: PC → MAR
S_FETCH_1: PC++
S_FETCH_2: [MAR] → IR
S_DECODE_3: decode opcode
S_LDA_IMM_4: PC → MAR
S_LDA_IMM_5: PC++
S_LDA_IMM_6: [MAR] → A
```

### Project:
✅ **SESUAI PERSIS**
- Control signals per state sama
- Bus routing sama
- Register load timing sama

### Buku Contoh: BEQ (Example 13.22)
```
Jika Z=1: branch taken
  S_BEQ_4: PC → MAR
  S_BEQ_5: PC++
  S_BEQ_6: [MAR] → PC
  
Jika Z=0: branch not taken
  S_BEQ_7: PC++
```

### Project:
✅ **SESUAI PERSIS**
- `src/cpu/control_unit.vhd` line 261-273:
  - Conditional branch taken path
  - Conditional branch not taken path

---

## 10. TEST RESULTS

### Buku: Simulation waveforms (Example 13.13, 13.15, 13.17, 13.19, 13.21, 13.23)

### Project:
✅ **SESUAI + EXTENDED**
- `tb/tb_computer.vhd`:
  - 8 test cases (vs buku 6 contoh)
  - Assertions untuk verify hasil
  - Output: PASS semua

```
PASS Test1 LDA_IMM/LDB_IMM/ADD_AB → port_out_00 = 0x08
PASS Test2 ADD overflow → port_out_01 = 0x00 (Z=1)
PASS Test3 BEQ branch taken (port_out_02 untouched)
PASS Test3b BEQ target reached → port_out_03 = 0x55
PASS Test4 SUB_AB → port_out_04 = 0x07
PASS Test5 AND_AB → port_out_05 = 0x00
PASS Test6 OR_AB → port_out_06 = 0xFF
PASS Test7 INCA → port_out_07 = 0x80
PASS Test8 DECA → port_out_08 = 0x00
```

---

## 11. WAVEFORM (GTKWave)

### Buku: Simulation waveforms

### Project:
✅ **SESUAI**
- `sim/wave.ghw` generated
- Signals: clock, reset, address, data_in/out, write, IR, PC, A, B, CCR, state
- Bisa dibuka di GTKWave

---

## KESIMPULAN

| Aspek | Buku Ch.13 | Project | Status |
|-------|-----------|---------|--------|
| Memory Map | ✅ | ✅ | **SESUAI** |
| Instruction Set | ✅ | ✅ | **SESUAI PERSIS** |
| CPU Architecture | ✅ | ✅ | **SESUAI** |
| Data Path | ✅ | ✅ | **SESUAI PERSIS** |
| ALU Operations | ✅ | ✅ | **SESUAI PERSIS** |
| Control Unit FSM | ✅ | ✅ | **SESUAI PERSIS** |
| Memory System | ✅ | ✅ | **SESUAI PERSIS** |
| Program Memory | ✅ | ✅ | **SESUAI + EXTENDED** |
| Instruction Execution | ✅ | ✅ | **SESUAI PERSIS** |
| Test & Simulation | ✅ | ✅ | **SESUAI + EXTENDED** |
| Waveform Output | ✅ | ✅ | **SESUAI** |

---

## PERBEDAAN MINOR (Improvement)

1. **Test Program**: Project lebih lengkap (8 test vs 6 contoh buku)
2. **Testbench**: Project punya assertions, buku hanya waveform
3. **Folder Structure**: Project lebih rapi (cpu/, mem/, top/, tb/)
4. **Build Script**: Project punya run.sh, run.bat, Makefile
5. **Documentation**: Project punya README.md lengkap

---

## VERIFIKASI FINAL

✅ **Project 100% sesuai Chapter 13 buku**
✅ **Semua instruksi terimplementasi**
✅ **Semua test PASS**
✅ **Waveform bisa dibuka GTKWave**
✅ **Compile tanpa error**

**Status: COMPLETE & VERIFIED**
