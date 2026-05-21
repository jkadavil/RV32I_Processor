# RV32I 5-Stage Pipelined Processor

A fully functional 32-bit RISC-V (RV32I) processor implemented in Verilog, featuring a 5-stage pipeline with hazard detection, data forwarding, and byte-addressable memory.

## Key metrics

| Metric | Value |
|---|---|
| Technology | Xilinx Artix-7 (xc7a35t) |
| LUT utilization | 1,256 LUTs (2.36%) |
| Flip-flops | 577 FFs (0.54%) |
| Fmax | 67.3 MHz |
| Bubble sort CPI | 2.21 (226 instr, 28 stalls, 38 flushes) |

---

## Architecture

### Pipeline stages

| Stage | Module | Function |
|---|---|---|
| IF | `instr_mem` | Fetch instruction at PC |
| ID | `regfile`, `imm_gen`, `control_unit` | Decode, read registers, generate immediate |
| EX | `alu`, forwarding muxes | Execute, compute branch target |
| MEM | `data_mem` | Load / store with byte/halfword support |
| WB | — | Write result back to register file |

### Pipeline registers

`if_id_reg` → `id_ex_reg` → `ex_mem_reg` → `mem_wb_reg`

Each register supports flush (inject NOP bubble) and stall (hold current value) independently.

### Hazard handling

**Load-use stalls** (`hazard_unit`): When a load in EX is followed immediately by an instruction that reads its destination, the pipeline stalls for one cycle — PC and IF/ID freeze, a bubble is injected into ID/EX.

**Data forwarding** (`forwarding_unit`): Resolves RAW hazards without stalling by routing the most recent available value back to EX inputs. Priority: MEM result (2'b10) > WB result (2'b01) > register file (2'b00).

**Branch resolution**: Taken branches are resolved in the **EX stage**, flushing 2 instructions (IF and ID). This is one cycle better than MEM-stage resolution. `ex_pc_sel = ex_branch_taken | ex_jump` drives the PC redirect and pipeline flush.

**Branch condition**: The ALU computes SLT (signed less-than) for branch instructions. `result[0] = 1` means rs1 < rs2. BEQ/BNE use `alu_zero`; BLT/BGE use `alu_result[0]`.

---

## Supported instructions

**R-type:** ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU

**I-type:** ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, SLTIU

**Load:** LW, LH, LB, LHU, LBU

**Store:** SW, SH, SB

**Branch:** BEQ, BNE, BLT, BGE, BLTU, BGEU

**Jump:** JAL, JALR

**Upper immediate:** LUI, AUIPC

---

## File structure

```
src/
  riscv_pipe.v        — top-level pipeline
  instr_mem.v         — instruction memory (256 words)
  data_mem.v          — data memory, byte/halfword access
  regfile.v           — 32×32 register file, write-through forwarding
  control_unit.v      — combinational decode
  alu.v               — 10-operation ALU
  imm_gen.v           — immediate generator (all formats)
  if_id_reg.v         — IF/ID pipeline register
  id_ex_reg.v         — ID/EX pipeline register
  ex_mem_reg.v        — EX/MEM pipeline register
  mem_wb_reg.v        — MEM/WB pipeline register
  hazard_unit.v       — load-use stall detection
  forwarding_unit.v   — MEM/WB→EX forwarding

sim/
  tb_riscv_pipe.v     — testbench (5 tests)
  test1.mem           — ALU operations
  test2.mem           — word load/store
  test3.mem           — Fibonacci (branch-heavy)
  test4.mem           — byte/halfword memory
  test5_bubblesort.mem — bubble sort benchmark

constraints/
  riscv_pipe.xdc      — Artix-7 timing constraints (67 MHz)
```

---

## Simulation results

All 5 tests pass with automated PASS/FAIL checking.

```
TEST 1  ALU ops          10 instr   0 stalls   0 flushes   CPI 4.00 *
TEST 2  Load/store        8 instr   2 stalls   0 flushes   CPI 7.50 *
TEST 3  Fibonacci        54 instr   0 stalls   9 flushes   CPI 2.04
TEST 4  Byte/halfword    18 instr   1 stall    0 flushes   CPI 4.44 *
TEST 5  Bubble sort     226 instr  28 stalls  38 flushes   CPI 2.21
```

\* Tests 1, 2, 4 CPI is dominated by pipeline startup/drain overhead due to short instruction counts. Test 5 (bubble sort) is the meaningful CPI benchmark — long enough that startup overhead is negligible.

**Bubble sort breakdown:**
- 28 load-use stalls — one per inner loop iteration (lw→lw back-to-back)
- 38 branch flushes — back-edge branches (2 cycles each) plus taken no-swap branches
- Input: [64, 25, 12, 22, 11, 90, 3, 47] → Output: [3, 11, 12, 22, 25, 47, 64, 90] ✓

---

## Running in Vivado

**Simulation:**
1. Add all `src/` and `sim/` files to the project
2. Set `tb_riscv_pipe` as the simulation top
3. Run simulation for at least 25 µs

**Synthesis:**
1. Set `riscv_pipe` as the synthesis top
2. Add `constraints/riscv_pipe.xdc`
3. Run synthesis — expect ~1,256 LUTs, 577 FFs, timing met at 67 MHz

---

## Design decisions

**EX-stage branch resolution** reduces the branch penalty from 3 cycles to 2 cycles compared to MEM-stage resolution. For a branch-heavy workload like the Fibonacci test (9 taken branches), this saves 9 cycles — measurable at this scale.

**SLT for branch ALU operation** — using SUB result[0] as a less-than signal is unreliable because the LSB of a difference depends on operand parity, not magnitude. SLT gives result[0] = 1 iff rs1 < rs2 (signed), which is the correct and robust test.

**Write-through register file** — the regfile forwards WB data to read ports combinationally when rs1/rs2 matches the write address. This eliminates one forwarding hazard case and keeps the forwarding unit simpler.

**Byte-addressable data memory** — `data_mem` uses byte enables for sub-word writes and mux logic for sub-word reads, supporting all five RV32I load widths and three store widths without requiring separate byte memories.
