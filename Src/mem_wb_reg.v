`timescale 1ns / 1ps
module mem_wb_reg (
    input         clk,
    input         rst,
    // control
    input         reg_write_in,
    input         mem_to_reg_in,
    input  [6:0]  opcode_in,
    // data
    input  [31:0] mem_rdata_in,
    input  [31:0] alu_result_in,
    input  [31:0] pc_plus4_in,
    input  [4:0]  rd_in,
    // outputs
    output reg        reg_write_out,
    output reg        mem_to_reg_out,
    output reg [6:0]  opcode_out,
    output reg [31:0] mem_rdata_out,
    output reg [31:0] alu_result_out,
    output reg [31:0] pc_plus4_out,
    output reg [4:0]  rd_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_write_out  <= 0;
            mem_to_reg_out <= 0;
            opcode_out     <= 7'b0;
            mem_rdata_out  <= 32'b0;
            alu_result_out <= 32'b0;
            pc_plus4_out   <= 32'b0;
            rd_out         <= 5'b0;
        end else begin
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            opcode_out     <= opcode_in;
            mem_rdata_out  <= mem_rdata_in;
            alu_result_out <= alu_result_in;
            pc_plus4_out   <= pc_plus4_in;
            rd_out         <= rd_in;
        end
    end
endmodule
