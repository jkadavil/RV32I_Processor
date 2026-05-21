`timescale 1ns / 1ps
module id_ex_reg (
    input         clk,
    input         rst,
    input         flush,
    // control signals
    input         reg_write_in,
    input         mem_read_in,
    input         mem_write_in,
    input         mem_to_reg_in,
    input         alu_src_in,
    input         branch_in,
    input         jump_in,
    input  [3:0]  alu_ctrl_in,
    // data
    input  [31:0] pc_in,
    input  [31:0] rdata1_in,
    input  [31:0] rdata2_in,
    input  [31:0] imm_in,
    // register addresses (needed by forwarding unit)
    input  [4:0]  rs1_in,
    input  [4:0]  rs2_in,
    input  [4:0]  rd_in,
    input  [2:0]  funct3_in,
    input  [6:0]  opcode_in,
    // outputs
    output reg        reg_write_out,
    output reg        mem_read_out,
    output reg        mem_write_out,
    output reg        mem_to_reg_out,
    output reg        alu_src_out,
    output reg        branch_out,
    output reg        jump_out,
    output reg [3:0]  alu_ctrl_out,
    output reg [31:0] pc_out,
    output reg [31:0] rdata1_out,
    output reg [31:0] rdata2_out,
    output reg [31:0] imm_out,
    output reg [4:0]  rs1_out,
    output reg [4:0]  rs2_out,
    output reg [4:0]  rd_out,
    output reg [2:0]  funct3_out,
    output reg [6:0]  opcode_out
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            reg_write_out  <= 0;
            mem_read_out   <= 0;
            mem_write_out  <= 0;
            mem_to_reg_out <= 0;
            alu_src_out    <= 0;
            branch_out     <= 0;
            jump_out       <= 0;
            alu_ctrl_out   <= 4'b0;
            pc_out         <= 32'b0;
            rdata1_out     <= 32'b0;
            rdata2_out     <= 32'b0;
            imm_out        <= 32'b0;
            rs1_out        <= 5'b0;
            rs2_out        <= 5'b0;
            rd_out         <= 5'b0;
            funct3_out     <= 3'b0;
            opcode_out     <= 7'b0;
        end else begin
            reg_write_out  <= reg_write_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            alu_src_out    <= alu_src_in;
            branch_out     <= branch_in;
            jump_out       <= jump_in;
            alu_ctrl_out   <= alu_ctrl_in;
            pc_out         <= pc_in;
            rdata1_out     <= rdata1_in;
            rdata2_out     <= rdata2_in;
            imm_out        <= imm_in;
            rs1_out        <= rs1_in;
            rs2_out        <= rs2_in;
            rd_out         <= rd_in;
            funct3_out     <= funct3_in;
            opcode_out     <= opcode_in;
        end
    end
endmodule
