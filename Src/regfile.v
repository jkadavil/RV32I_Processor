`timescale 1ns / 1ps
// src/regfile.v
module regfile (
    input         clk,
    input         we,          // write enable
    input  [4:0]  rs1, rs2,   // read addresses
    input  [4:0]  rd,          // write address
    input  [31:0] wdata,       // write data
    output [31:0] rdata1,
    output [31:0] rdata2
);
    reg [31:0] regs [0:31];

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'b0;
    end

    // Asynchronous read - combinational, no clock needed
    // FIXED - write-through forwarding:
assign rdata1 = (rs1 == 5'b0)        ? 32'b0  :
                (we && rd == rs1)     ? wdata  :
                                        regs[rs1];

assign rdata2 = (rs2 == 5'b0)        ? 32'b0  :
                (we && rd == rs2)     ? wdata  :
                                        regs[rs2];
    // Synchronous write
    always @(posedge clk) begin
        if (we && rd != 5'b0)
            regs[rd] <= wdata;
    end

endmodule
