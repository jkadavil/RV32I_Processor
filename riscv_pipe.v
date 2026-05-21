`timescale 1ns/1ps
// =============================================================
// riscv_pipe.v  -  5-stage RISC-V pipeline (RV32I subset)
//
// =============================================================
(* dont_touch = "yes" *)
(* keep_hierarchy = "yes" *)
module riscv_pipe (
    input         clk,
    input         rst,
    output [31:0] pc_out,
    output [31:0] instr_count_out,
    output [31:0] stall_count_out,
    output [31:0] flush_count_out
);

// ============================================================
// SECTION 0 - PERFORMANCE COUNTERS
// ============================================================

reg [31:0] instr_count;
reg [31:0] stall_count;
reg [31:0] flush_count;

always @(posedge clk or posedge rst) begin
    if (rst) instr_count <= 0;
    else if (wb_reg_write) instr_count <= instr_count + 1;
end

always @(posedge clk or posedge rst) begin
    if (rst) stall_count <= 0;
    else if (hazard_stall) stall_count <= stall_count + 1;
end

// Flush counter: fires when EX redirects the PC
always @(posedge clk or posedge rst) begin
    if (rst) flush_count <= 0;
    else if (ex_pc_sel) flush_count <= flush_count + 1;
end

assign instr_count_out = instr_count;
assign stall_count_out = stall_count;
assign flush_count_out = flush_count;

// ============================================================
// SECTION 1 - IF stage
// ============================================================

reg  [31:0] pc;
wire [31:0] pc_plus4;
wire [31:0] pc_next;
wire [31:0] if_instr;

assign pc_out   = pc;
assign pc_plus4 = pc + 32'd4;

always @(posedge clk or posedge rst) begin
    if (rst) pc <= 32'b0;
    else     pc <= pc_next;
end

instr_mem imem (
    .addr  (pc),
    .instr (if_instr)
);

// ============================================================
// SECTION 2 - IF/ID register
// ============================================================

wire        if_id_stall;
wire        if_id_flush;
wire [31:0] id_pc;
wire [31:0] id_instr;

if_id_reg if_id (
    .clk      (clk),
    .rst      (rst),
    .stall    (if_id_stall),
    .flush    (if_id_flush),
    .pc_in    (pc),
    .instr_in (if_instr),
    .pc_out   (id_pc),
    .instr_out(id_instr)
);

// ============================================================
// SECTION 3 - ID stage
// ============================================================

wire [6:0] id_opcode = id_instr[6:0];
wire [4:0] id_rd     = id_instr[11:7];
wire [2:0] id_funct3 = id_instr[14:12];
wire [4:0] id_rs1    = id_instr[19:15];
wire [4:0] id_rs2    = id_instr[24:20];
wire [6:0] id_funct7 = id_instr[31:25];

wire        id_reg_write, id_mem_read, id_mem_write;
wire        id_mem_to_reg, id_alu_src, id_branch, id_jump;
wire [3:0]  id_alu_ctrl;

control_unit cu (
    .opcode     (id_opcode),
    .funct3     (id_funct3),
    .funct7     (id_funct7),
    .reg_write  (id_reg_write),
    .mem_read   (id_mem_read),
    .mem_write  (id_mem_write),
    .mem_to_reg (id_mem_to_reg),
    .alu_src    (id_alu_src),
    .branch     (id_branch),
    .jump       (id_jump),
    .alu_ctrl   (id_alu_ctrl)
);

// WB signals (declared here, driven from SECTION 9)
wire        wb_reg_write;
wire [4:0]  wb_rd;
wire [31:0] wb_wdata;

wire [31:0] id_rdata1, id_rdata2;

regfile rf (
    .clk    (clk),
    .we     (wb_reg_write),
    .rs1    (id_rs1),
    .rs2    (id_rs2),
    .rd     (wb_rd),
    .wdata  (wb_wdata),
    .rdata1 (id_rdata1),
    .rdata2 (id_rdata2)
);

wire [31:0] id_imm;
imm_gen ig (
    .instr (id_instr),
    .imm   (id_imm)
);

// ============================================================
// SECTION 4 - ID/EX register
// ============================================================

wire        id_ex_flush;
wire        ex_reg_write, ex_mem_read, ex_mem_write;
wire        ex_mem_to_reg, ex_alu_src, ex_branch, ex_jump;
wire [3:0]  ex_alu_ctrl;
wire [31:0] ex_pc, ex_rdata1, ex_rdata2, ex_imm;
wire [4:0]  ex_rs1, ex_rs2, ex_rd;
wire [2:0]  ex_funct3;
wire [6:0]  ex_opcode;

id_ex_reg id_ex (
    .clk            (clk),
    .rst            (rst),
    .flush          (id_ex_flush),
    .reg_write_in   (id_reg_write),
    .mem_read_in    (id_mem_read),
    .mem_write_in   (id_mem_write),
    .mem_to_reg_in  (id_mem_to_reg),
    .alu_src_in     (id_alu_src),
    .branch_in      (id_branch),
    .jump_in        (id_jump),
    .alu_ctrl_in    (id_alu_ctrl),
    .pc_in          (id_pc),
    .rdata1_in      (id_rdata1),
    .rdata2_in      (id_rdata2),
    .imm_in         (id_imm),
    .rs1_in         (id_rs1),
    .rs2_in         (id_rs2),
    .rd_in          (id_rd),
    .funct3_in      (id_funct3),
    .opcode_in      (id_opcode),
    .reg_write_out  (ex_reg_write),
    .mem_read_out   (ex_mem_read),
    .mem_write_out  (ex_mem_write),
    .mem_to_reg_out (ex_mem_to_reg),
    .alu_src_out    (ex_alu_src),
    .branch_out     (ex_branch),
    .jump_out       (ex_jump),
    .alu_ctrl_out   (ex_alu_ctrl),
    .pc_out         (ex_pc),
    .rdata1_out     (ex_rdata1),
    .rdata2_out     (ex_rdata2),
    .imm_out        (ex_imm),
    .rs1_out        (ex_rs1),
    .rs2_out        (ex_rs2),
    .rd_out         (ex_rd),
    .funct3_out     (ex_funct3),
    .opcode_out     (ex_opcode)
);

// ============================================================
// SECTION 5 - EX stage
// ============================================================

wire [1:0] forward_a, forward_b;

// WB-stage signals needed for forwarding mux
wire        wb_mem_to_reg;
wire [31:0] wb_mem_rdata;
wire [31:0] wb_alu_result;
wire [31:0] wb_pc_plus4;
wire [6:0]  wb_opcode;

// MEM-stage ALU result needed for forwarding
wire [31:0] mem_alu_result;

// Forwarding mux: WB selects between mem data and ALU result
wire [31:0] mem_wb_forward_val = wb_mem_to_reg ? wb_mem_rdata : wb_alu_result;

// ALU input A: LUI uses 0, AUIPC uses PC, others use rs1
wire [31:0] ex_alu_a_base =
    (ex_opcode == 7'b0110111) ? 32'b0  :   // LUI
    (ex_opcode == 7'b0010111) ? ex_pc  :   // AUIPC
                                ex_rdata1;

wire [31:0] ex_alu_input_a =
    (forward_a == 2'b10) ? mem_alu_result     :
    (forward_a == 2'b01) ? mem_wb_forward_val :
                           ex_alu_a_base;

wire [31:0] ex_forwarded_b =
    (forward_b == 2'b10) ? mem_alu_result     :
    (forward_b == 2'b01) ? mem_wb_forward_val :
                           ex_rdata2;

wire [31:0] ex_alu_input_b = ex_alu_src ? ex_imm : ex_forwarded_b;

wire [31:0] ex_alu_result;
wire        ex_alu_zero;

alu u_alu (
    .a      (ex_alu_input_a),
    .b      (ex_alu_input_b),
    .ctrl   (ex_alu_ctrl),
    .result (ex_alu_result),
    .zero   (ex_alu_zero)
);

wire [31:0] ex_pc_plus4  = ex_pc + 32'd4;
wire [31:0] ex_pc_branch = ex_pc + ex_imm;

// JALR target: (rs1 + imm) with LSB cleared per spec
wire [31:0] ex_pc_jump =
    (ex_opcode == 7'b1100111) ? ((ex_alu_input_a + ex_imm) & ~32'b1) :
                                 (ex_pc + ex_imm);

// Branch condition decode
wire ex_branch_taken = ex_branch & (
    (ex_funct3 == 3'b000 &&  ex_alu_zero)      ||  // BEQ
    (ex_funct3 == 3'b001 && !ex_alu_zero)      ||  // BNE
    (ex_funct3 == 3'b100 &&  ex_alu_result[0]) ||  // BLT
    (ex_funct3 == 3'b101 && !ex_alu_result[0])     // BGE
);

wire [31:0] ex_pc_target = ex_jump ? ex_pc_jump : ex_pc_branch;

// *** EX-stage PC redirect (was MEM-stage in v1) ***
// Resolving here saves one flush cycle per taken branch/jump.
wire ex_pc_sel = ex_branch_taken | ex_jump;

// ============================================================
// SECTION 6 - EX/MEM register
// ============================================================

wire        mem_reg_write, mem_mem_read, mem_mem_write;
wire        mem_mem_to_reg, mem_branch, mem_jump;
wire        mem_branch_taken;
wire [31:0] mem_pc_target, mem_pc_plus4;
wire [31:0] mem_rdata2;
wire        mem_alu_zero;
wire [4:0]  mem_rd;
wire [2:0]  mem_funct3;
wire [6:0]  mem_opcode;

ex_mem_reg ex_mem (
    .clk             (clk),
    .rst             (rst),
    // flush on EX redirect so speculative instructions don't commit
    .flush           (ex_pc_sel),
    .reg_write_in    (ex_reg_write),
    .mem_read_in     (ex_mem_read),
    .mem_write_in    (ex_mem_write),
    .mem_to_reg_in   (ex_mem_to_reg),
    .branch_in       (ex_branch),
    .jump_in         (ex_jump),
    .funct3_in       (ex_funct3),
    .opcode_in       (ex_opcode),
    .branch_taken_in (ex_branch_taken),
    .pc_target_in    (ex_pc_target),
    .alu_result_in   (ex_alu_result),
    .alu_zero_in     (ex_alu_zero),
    .rdata2_in       (ex_forwarded_b),
    .pc_plus4_in     (ex_pc_plus4),
    .rd_in           (ex_rd),
    .reg_write_out   (mem_reg_write),
    .mem_read_out    (mem_mem_read),
    .mem_write_out   (mem_mem_write),
    .mem_to_reg_out  (mem_mem_to_reg),
    .branch_out      (mem_branch),
    .jump_out        (mem_jump),
    .funct3_out      (mem_funct3),
    .opcode_out      (mem_opcode),
    .branch_taken_out(mem_branch_taken),
    .pc_target_out   (mem_pc_target),
    .alu_result_out  (mem_alu_result),
    .alu_zero_out    (mem_alu_zero),
    .rdata2_out      (mem_rdata2),
    .pc_plus4_out    (mem_pc_plus4),
    .rd_out          (mem_rd)
);

// ============================================================
// SECTION 7 - MEM stage
// ============================================================

wire [31:0] mem_rdata;

data_mem dmem (
    .clk       (clk),
    .mem_read  (mem_mem_read),
    .mem_write (mem_mem_write),
    .funct3    (mem_funct3),
    .addr      (mem_alu_result),
    .wdata     (mem_rdata2),
    .rdata     (mem_rdata)
);

// MEM-stage no longer drives PC redirect - kept for completeness
// mem_pc_sel is intentionally unused; resolution is now in EX.

// ============================================================
// SECTION 8 - MEM/WB register
// ============================================================

mem_wb_reg mem_wb (
    .clk           (clk),
    .rst           (rst),
    .reg_write_in  (mem_reg_write),
    .mem_to_reg_in (mem_mem_to_reg),
    .opcode_in     (mem_opcode),
    .mem_rdata_in  (mem_rdata),
    .alu_result_in (mem_alu_result),
    .pc_plus4_in   (mem_pc_plus4),
    .rd_in         (mem_rd),
    .reg_write_out (wb_reg_write),
    .mem_to_reg_out(wb_mem_to_reg),
    .opcode_out    (wb_opcode),
    .mem_rdata_out (wb_mem_rdata),
    .alu_result_out(wb_alu_result),
    .pc_plus4_out  (wb_pc_plus4),
    .rd_out        (wb_rd)
);

// ============================================================
// SECTION 9 - WB stage
// ============================================================

assign wb_wdata =
    (wb_opcode == 7'b1101111 || wb_opcode == 7'b1100111) ? wb_pc_plus4  :
    wb_mem_to_reg                                         ? wb_mem_rdata :
                                                            wb_alu_result;

// ============================================================
// SECTION 10 - Hazard detection, forwarding, PC control
// ============================================================

wire hazard_stall;
wire hazard_id_ex_flush;

hazard_unit hu (
    .id_rs1             (id_rs1),
    .id_rs2             (id_rs2),
    .ex_mem_read        (ex_mem_read),
    .ex_rd              (ex_rd),
    .stall              (hazard_stall),
    .id_ex_flush_hazard (hazard_id_ex_flush)
);

// ex_alu_src removed from forwarding_unit (was unused inside module)
forwarding_unit fu (
    .ex_rs1        (ex_rs1),
    .ex_rs2        (ex_rs2),
    .mem_rd        (mem_rd),
    .mem_reg_write (mem_reg_write),
    .wb_rd         (wb_rd),
    .wb_reg_write  (wb_reg_write),
    .forward_a     (forward_a),
    .forward_b     (forward_b)
);

// IF/ID: stall on load-use; flush on EX redirect
assign if_id_stall = hazard_stall;
assign if_id_flush = ex_pc_sel;

// ID/EX: flush on EX redirect OR load-use bubble
assign id_ex_flush = ex_pc_sel | hazard_id_ex_flush;

// PC select priority: stall > EX redirect > increment
assign pc_next =
    hazard_stall ? pc            :
    ex_pc_sel    ? ex_pc_target  :
                   pc_plus4;

endmodule
