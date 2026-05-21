`timescale 1ns / 1ps
module if_id_reg (
    input         clk,
    input         rst,
    input         stall,    // freeze this register (don't update)
    input         flush,    // inject a bubble (clear to NOP)
    input  [31:0] pc_in,
    input  [31:0] instr_in,
    output reg [31:0] pc_out,
    output reg [31:0] instr_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out    <= 32'b0;
            instr_out <= 32'b0;
        end else if (flush) begin
            pc_out    <= 32'b0;
            instr_out <= 32'h00000013; // NOP = addi x0, x0, 0
        end else if (!stall) begin
            pc_out    <= pc_in;
            instr_out <= instr_in;
        end
        // stall: hold current value, do nothing
    end
endmodule
