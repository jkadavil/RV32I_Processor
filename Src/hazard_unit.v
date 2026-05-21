`timescale 1ns / 1ps
module hazard_unit (
    // The instruction currently in ID is trying to read these registers
    input  [4:0] id_rs1,
    input  [4:0] id_rs2,
    // The instruction currently in EX - is it a load?
    input        ex_mem_read,
    input  [4:0] ex_rd,
    // Outputs
    output       stall,    // freeze IF/ID and PC for one cycle
    output       id_ex_flush_hazard  // inject bubble into ID/EX
);
    // Load-use hazard: LW in EX, and its destination matches
    // either source of the instruction currently in ID
    wire load_use = ex_mem_read &&
                    (ex_rd != 5'b0) &&
                    ((ex_rd == id_rs1) || (ex_rd == id_rs2));

    assign stall             = load_use;
    assign id_ex_flush_hazard = load_use;

endmodule
