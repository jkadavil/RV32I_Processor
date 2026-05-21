`timescale 1ns / 1ps
module ex_mem_reg (
    input         clk,
    input         rst,
    input         flush,
    // control
    input         reg_write_in,
    input         mem_read_in,
    input         mem_write_in,
    input         mem_to_reg_in,
    input         branch_in,
    input         jump_in,
    input  [2:0]  funct3_in,
    input  [6:0]  opcode_in,
    // data
    input         branch_taken_in,
    input  [31:0] pc_target_in,
    input  [31:0] alu_result_in,
    input         alu_zero_in,
    input  [31:0] rdata2_in,
    input  [31:0] pc_plus4_in,
    input  [4:0]  rd_in,
    // outputs
    output reg        reg_write_out,
    output reg        mem_read_out,
    output reg        mem_write_out,
    output reg        mem_to_reg_out,
    output reg        branch_out,
    output reg        jump_out,
    output reg [2:0]  funct3_out,
    output reg [6:0]  opcode_out,
    output reg        branch_taken_out,
    output reg [31:0] pc_target_out,
    output reg [31:0] alu_result_out,
    output reg        alu_zero_out,
    output reg [31:0] rdata2_out,
    output reg [31:0] pc_plus4_out,
    output reg [4:0]  rd_out
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            reg_write_out   <= 0;
            mem_read_out    <= 0;
            mem_write_out   <= 0;
            mem_to_reg_out  <= 0;
            branch_out      <= 0;
            jump_out        <= 0;
            funct3_out      <= 3'b0;
            opcode_out      <= 7'b0;
            branch_taken_out<= 0;
            pc_target_out   <= 32'b0;
            alu_result_out  <= 32'b0;
            alu_zero_out    <= 0;
            rdata2_out      <= 32'b0;
            pc_plus4_out    <= 32'b0;
            rd_out          <= 5'b0;
        end else begin
            reg_write_out   <= reg_write_in;
            mem_read_out    <= mem_read_in;
            mem_write_out   <= mem_write_in;
            mem_to_reg_out  <= mem_to_reg_in;
            branch_out      <= branch_in;
            jump_out        <= jump_in;
            funct3_out      <= funct3_in;
            opcode_out      <= opcode_in;
            branch_taken_out<= branch_taken_in;
            pc_target_out   <= pc_target_in;
            alu_result_out  <= alu_result_in;
            alu_zero_out    <= alu_zero_in;
            rdata2_out      <= rdata2_in;
            pc_plus4_out    <= pc_plus4_in;
            rd_out          <= rd_in;
        end
    end
endmodule
