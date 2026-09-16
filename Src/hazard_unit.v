`timescale 1ns / 1ps
module hazard_unit (
    input  [4:0] id_rs1,
    input  [4:0] id_rs2,
    input        id_uses_rs1,
    input        id_uses_rs2,
    input        ex_mem_read,
    input  [4:0] ex_rd,
    output       stall,
    output       id_ex_flush_hazard
);
    wire rs1_hazard = id_uses_rs1 && (ex_rd == id_rs1);
    wire rs2_hazard = id_uses_rs2 && (ex_rd == id_rs2);

    wire load_use = ex_mem_read &&
                    (ex_rd != 5'b0) &&
                    (rs1_hazard || rs2_hazard);

    assign stall              = load_use;
    assign id_ex_flush_hazard = load_use;
endmodule
