# RV32I 5-Stage Pipelined Processor

A 32-bit RV32I processor implemented in Verilog using a classic five-stage pipeline with data forwarding, hazard detection, control-hazard recovery, byte-addressable memory, and directed verification.

The processor was designed and verified in AMD Vivado targeting the Xilinx Zynq-7000 XC7Z020 (`xc7z020clg400-1`).

## Architecture

The processor uses the classic five-stage RISC-V pipeline:

```text
IF → ID → EX → MEM → WB
```

The stages are separated by four pipeline registers:

```text
PC / Instruction Memory
        │
        ▼
       IF
        │
     IF/ID
        │
        ▼
       ID
        │
     ID/EX
        │
        ▼
       EX
        │
     EX/MEM
        │
        ▼
       MEM
        │
     MEM/WB
        │
        ▼
       WB
```

### Instruction Fetch — IF

The fetch stage maintains the program counter and reads the current instruction from instruction memory.

Normally:

```text
PCnext = PC + 4
```

A taken branch or jump redirects the PC to the target address. A load-use hazard can hold the PC while a pipeline bubble is inserted.

Control-flow redirection has priority over a data-hazard stall so a wrong-path instruction cannot prevent a resolved branch or jump from redirecting execution.

### Instruction Decode — ID

The decode stage:

* extracts `rs1`, `rs2`, `rd`, `funct3`, `funct7`, and opcode
* reads the register file
* generates immediate values
* generates control signals
* identifies whether the instruction actually consumes `rs1` and/or `rs2`

Source-use information is passed into the hazard logic to prevent false dependencies on instruction fields that are not actually register operands.

### Execute — EX

The execute stage contains:

* ALU
* operand forwarding multiplexers
* signed and unsigned branch comparison
* branch target generation
* JAL/JALR target generation

Forwarding allows dependent instructions to consume recently generated values without waiting for those values to be written back to the register file.

Conditional branches are resolved in EX.

Supported branch comparisons include:

```text
BEQ
BNE
BLT
BGE
BLTU
BGEU
```

Both signed and unsigned comparisons are implemented explicitly.

### Memory — MEM

The memory stage supports byte, halfword, and word accesses.

Supported load instructions:

```text
LB
LH
LW
LBU
LHU
```

Supported store instructions:

```text
SB
SH
SW
```

Store data participates in the forwarding network so an ALU result can be stored by a following instruction without waiting for register-file writeback.

### Writeback — WB

The writeback stage selects the architectural value written to `rd`.

Possible sources include:

```text
ALU result
Memory load data
PC + 4
```

`PC + 4` is used for JAL and JALR link-register writeback.

The final writeback value also participates in forwarding, allowing jump link values and other results to be consumed by dependent instructions.

## Hazard Handling

### EX/MEM Forwarding

When an instruction in EX depends on a value produced by an older instruction, the forwarding unit can bypass the result directly into the ALU operands.

Conceptually:

```text
EX/MEM result ─────┐
                   │
MEM/WB result ─────┼──► Forwarding MUX ──► ALU
                   │
Register value ────┘
```

EX/MEM forwarding receives priority because it contains the most recent matching result.

### Load-Use Hazard

A load cannot provide its memory result early enough for an immediately following dependent instruction.

For:

```asm
lw   x5, 0(x1)
add  x6, x5, x2
```

the processor inserts one bubble.

The hazard unit:

```text
holds PC
holds IF/ID
flushes ID/EX
```

After the bubble, the loaded value can be forwarded from the writeback path.

Hazard detection uses source-operand information so fields that only resemble register numbers do not generate false stalls.

### Control Hazards

Branches and jumps are resolved in EX.

When a redirect occurs:

```text
EX resolves branch/jump
        │
        ▼
new PC selected
        │
        ├── flush IF/ID
        └── flush ID/EX
```

The branch or jump itself continues into MEM. Only the younger wrong-path instructions are removed.

This is particularly important for JAL and JALR because the redirecting instruction must remain in the pipeline long enough to write `PC + 4` into its destination register.

## Supported RV32I Instructions

### Integer Arithmetic

```text
ADD   SUB
ADDI
```

### Logical Operations

```text
AND   OR   XOR
ANDI  ORI  XORI
```

### Shifts

```text
SLL   SRL   SRA
SLLI  SRLI  SRAI
```

### Comparisons

```text
SLT   SLTU
SLTI  SLTIU
```

### Upper Immediates

```text
LUI
AUIPC
```

### Loads

```text
LB
LH
LW
LBU
LHU
```

### Stores

```text
SB
SH
SW
```

### Conditional Branches

```text
BEQ
BNE
BLT
BGE
BLTU
BGEU
```

### Jumps

```text
JAL
JALR
```

## Verification

The processor is verified using a self-checking Verilog testbench.

Six directed test programs currently exercise the processor.

### Test 1 — ALU

Tests basic arithmetic and logical execution.

### Test 2 — Load/Store

Tests word memory accesses and load-use hazard behavior.

A real load-use dependency generates one pipeline stall.

### Test 3 — Fibonacci

Executes a control-flow-heavy Fibonacci program to exercise arithmetic, forwarding, branches, and repeated pipeline redirects.

### Test 4 — Byte/Halfword Memory

Verifies:

```text
LB
LBU
LH
LHU
LW
```

along with a dependent arithmetic operation.

### Test 5 — Bubble Sort

Executes an eight-element bubble-sort program.

Expected result:

```text
3 11 12 22 25 47 64 90
```

The simulation verifies each sorted value automatically.

### Test 6 — Pipeline Corner Cases

A directed regression specifically verifies pipeline-control and forwarding behavior.

It checks:

* BEQ taken behavior
* BNE taken and not-taken behavior
* BLT
* BGE
* BLTU
* BGEU
* JAL redirection
* JAL link-register writeback
* immediate consumption of a JAL link value
* JALR redirection
* JALR link-register writeback
* JALR target bit-zero clearing
* immediate consumption of a JALR link value
* wrong-path instruction flushing
* LUI forwarding corner cases
* AUIPC forwarding corner cases
* suppression of false load-use hazards
* preservation of genuine load-use stalls

The directed test produces exactly one genuine load-use stall and eight expected control-flow redirects.

Current regression result:

```text
===========================
ALL TESTS PASSED
===========================
```

## FPGA Synthesis

The processor has been synthesized in Vivado 2025.2 targeting:

```text
xc7z020clg400-1
```

Current post-synthesis resource utilization:

| Resource               |  Used | Available | Utilization |
| ---------------------- | ----: | --------: | ----------: |
| Slice LUTs             | 1,303 |    53,200 |       2.45% |
| LUT as Logic           | 1,127 |    53,200 |       2.12% |
| LUT as Distributed RAM |   176 |    17,400 |       1.01% |
| Slice Registers        |   580 |   106,400 |       0.55% |
| DSPs                   |     0 |       220 |       0.00% |
| Block RAM Tiles        |     0 |       140 |       0.00% |

The current instruction and data memories use asynchronous reads and synthesize as distributed LUT RAM rather than native block RAM.

A future memory-system revision can introduce synchronous memory interfaces if block-RAM inference is desired.

## Performance Counters

The processor currently exposes counters for:

```text
instruction/writeback events
pipeline stalls
control-flow redirects
```

The current instruction counter increments on register-writeback events and therefore should not yet be interpreted as a complete architectural retired-instruction counter.

As a result, CPI values printed by the current testbench are useful for internal comparison but are not presented as architectural CPI measurements.

A future revision can propagate pipeline-valid state and count all retired instructions, including stores and branches.

## Project Structure

```text
RV32I_Processor/
│
├── riscv_pipe.v
├── control_unit.v
├── alu.v
├── regfile.v
├── imm_gen.v
│
├── forwarding_unit.v
├── hazard_unit.v
│
├── if_id_reg.v
├── id_ex_reg.v
├── ex_mem_reg.v
├── mem_wb_reg.v
│
├── instr_mem.v
├── data_mem.v
│
├── tb_riscv_pipe.v
│
├── test1.mem
├── test2.mem
├── test3.mem
├── test4.mem
├── test5_bubblesort.mem
└── test6_cornercases.mem
```

## Tools

* Verilog HDL
* AMD Vivado 2025.2
* XSim
* Xilinx Zynq-7000 XC7Z020

## Current Status

The current RTL passes the complete six-test behavioral regression, including directed branch, jump, forwarding, hazard, memory, Fibonacci, and bubble-sort verification.

Future work will focus on verification depth, architectural retirement tracking, memory implementation, and FPGA timing optimization.
