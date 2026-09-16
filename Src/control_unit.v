`timescale 1ns / 1ps
module control_unit (
    input  [6:0] opcode,
    input  [2:0] funct3,
    input  [6:0] funct7,
    output reg       reg_write,
    output reg       mem_read,
    output reg       mem_write,
    output reg       mem_to_reg,
    output reg       alu_src,
    output reg       branch,
    output reg       jump,
    output reg       uses_rs1,
    output reg       uses_rs2,
    output reg [3:0] alu_ctrl
);
    localparam R_TYPE = 7'b0110011;
    localparam I_ALU  = 7'b0010011;
    localparam I_LOAD = 7'b0000011;
    localparam S_TYPE = 7'b0100011;
    localparam B_TYPE = 7'b1100011;
    localparam JAL    = 7'b1101111;
    localparam JALR   = 7'b1100111;
    localparam LUI    = 7'b0110111;
    localparam AUIPC  = 7'b0010111;

    always @(*) begin
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        alu_src    = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        uses_rs1   = 1'b0;
        uses_rs2   = 1'b0;
        alu_ctrl   = 4'b0000;

        case (opcode)
            R_TYPE: begin
                reg_write = 1'b1;
                uses_rs1  = 1'b1;
                uses_rs2  = 1'b1;
                case ({funct7[5], funct3})
                    4'b0000: alu_ctrl = 4'b0000; // ADD
                    4'b1000: alu_ctrl = 4'b0001; // SUB
                    4'b0111: alu_ctrl = 4'b0010; // AND
                    4'b0110: alu_ctrl = 4'b0011; // OR
                    4'b0100: alu_ctrl = 4'b0100; // XOR
                    4'b0001: alu_ctrl = 4'b0101; // SLL
                    4'b0101: alu_ctrl = 4'b0110; // SRL
                    4'b1101: alu_ctrl = 4'b0111; // SRA
                    4'b0010: alu_ctrl = 4'b1000; // SLT
                    4'b0011: alu_ctrl = 4'b1001; // SLTU
                    default: alu_ctrl = 4'b0000;
                endcase
            end

            I_ALU: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                uses_rs1  = 1'b1;
                case (funct3)
                    3'b000: alu_ctrl = 4'b0000; // ADDI
                    3'b111: alu_ctrl = 4'b0010; // ANDI
                    3'b110: alu_ctrl = 4'b0011; // ORI
                    3'b100: alu_ctrl = 4'b0100; // XORI
                    3'b001: alu_ctrl = 4'b0101; // SLLI
                    3'b101: alu_ctrl = funct7[5] ? 4'b0111 : 4'b0110; // SRAI/SRLI
                    3'b010: alu_ctrl = 4'b1000; // SLTI
                    3'b011: alu_ctrl = 4'b1001; // SLTIU
                    default: alu_ctrl = 4'b0000;
                endcase
            end

            I_LOAD: begin
                reg_write  = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_src    = 1'b1;
                uses_rs1   = 1'b1;
                alu_ctrl   = 4'b0000;
            end

            S_TYPE: begin
                mem_write = 1'b1;
                alu_src   = 1'b1;
                uses_rs1  = 1'b1; // address base
                uses_rs2  = 1'b1; // store data
                alu_ctrl  = 4'b0000;
            end

            B_TYPE: begin
                branch    = 1'b1;
                uses_rs1  = 1'b1;
                uses_rs2  = 1'b1;
                // Branch comparison is performed explicitly in EX.
                alu_ctrl  = 4'b0001; // harmless SUB for debug/zero visibility
            end

            JAL: begin
                reg_write = 1'b1;
                jump      = 1'b1;
            end

            JALR: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                alu_src   = 1'b1;
                uses_rs1  = 1'b1;
                alu_ctrl  = 4'b0000;
            end

            LUI: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_ctrl  = 4'b0000;
            end

            AUIPC: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_ctrl  = 4'b0000;
            end

            default: ;
        endcase
    end
endmodule
