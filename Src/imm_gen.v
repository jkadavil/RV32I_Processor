`timescale 1ns / 1ps
// src/imm_gen.v
module imm_gen (
    input  [31:0] instr,
    output reg [31:0] imm
);
    wire [6:0] opcode = instr[6:0];

    localparam I_ALU  = 7'b0010011;
    localparam I_LOAD = 7'b0000011;
    localparam JALR   = 7'b1100111;
    localparam S_TYPE = 7'b0100011;
    localparam B_TYPE = 7'b1100011;
    localparam JAL    = 7'b1101111;
    localparam LUI    = 7'b0110111;
    localparam AUIPC  = 7'b0010111;

    always @(*) begin
        case (opcode)
            I_ALU, I_LOAD, JALR:
                imm = {{20{instr[31]}}, instr[31:20]};

            S_TYPE:
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            B_TYPE:
                imm = {{19{instr[31]}}, instr[31], instr[7],
                       instr[30:25], instr[11:8], 1'b0};

            JAL:
                imm = {{11{instr[31]}}, instr[31], instr[19:12],
                       instr[20], instr[30:21], 1'b0};

            LUI, AUIPC:
                imm = {instr[31:12], 12'b0};

            default:
                imm = 32'b0;
        endcase
    end

endmodule
