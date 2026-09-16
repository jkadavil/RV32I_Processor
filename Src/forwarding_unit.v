`timescale 1ns/1ps
module forwarding_unit (
    input  [4:0] ex_rs1,
    input  [4:0] ex_rs2,
    input        ex_uses_rs1,
    input        ex_uses_rs2,
    input  [4:0] mem_rd,
    input        mem_reg_write,
    input        mem_mem_read,
    input  [4:0] wb_rd,
    input        wb_reg_write,
    output reg [1:0] forward_a,
    output reg [1:0] forward_b
);
    always @(*) begin
        forward_a = 2'b00;
        forward_b = 2'b00;

        // MEM has priority because it contains the newer value.
        // A load's data is not an EX/MEM ALU result, so do not forward
        // from MEM for loads; the load-use interlock makes the consumer
        // wait until the value is available in WB.
        if (ex_uses_rs1) begin
            if (mem_reg_write && !mem_mem_read &&
                (mem_rd != 5'b0) && (mem_rd == ex_rs1))
                forward_a = 2'b10;
            else if (wb_reg_write &&
                     (wb_rd != 5'b0) && (wb_rd == ex_rs1))
                forward_a = 2'b01;
        end

        if (ex_uses_rs2) begin
            if (mem_reg_write && !mem_mem_read &&
                (mem_rd != 5'b0) && (mem_rd == ex_rs2))
                forward_b = 2'b10;
            else if (wb_reg_write &&
                     (wb_rd != 5'b0) && (wb_rd == ex_rs2))
                forward_b = 2'b01;
        end
    end
endmodule
