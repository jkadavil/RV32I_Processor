`timescale 1ns / 1ps
// src/control_unit.v
module control_unit (
    input  [6:0] opcode,
    input  [2:0] funct3,
    input  [6:0] funct7,
    output reg       reg_write,
    output reg       mem_read,
    output reg       mem_write,
    output reg       mem_to_reg,  // 1 = load from mem, 0 = ALU result
    output reg       alu_src,     // 1 = immediate, 0 = rs2
    output reg       branch,
    output reg       jump,        // JAL/JALR
    output reg [3:0] alu_ctrl
);
    // Opcode constants
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
        // Safe defaults
        reg_write  = 0;
        mem_read   = 0;
        mem_write  = 0;
        mem_to_reg = 0;
        alu_src    = 0;
        branch     = 0;
        jump       = 0;
        alu_ctrl   = 4'b0000;  // ADD

        case (opcode)
            R_TYPE: begin
                reg_write = 1;
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
                reg_write = 1;
                alu_src   = 1;
                case (funct3)
                    3'b000: alu_ctrl = 4'b0000; // ADDI
                    3'b111: alu_ctrl = 4'b0010; // ANDI
                    3'b110: alu_ctrl = 4'b0011; // ORI
                    3'b100: alu_ctrl = 4'b0100; // XORI
                    3'b001: alu_ctrl = 4'b0101; // SLLI
                    3'b101: alu_ctrl = (funct7[5]) ? 4'b0111 : 4'b0110; // SRAI/SRLI
                    3'b010: alu_ctrl = 4'b1000; // SLTI
                    3'b011: alu_ctrl = 4'b1001; // SLTIU
                    default: alu_ctrl = 4'b0000;
                endcase
            end

            I_LOAD: begin
                reg_write  = 1;
                mem_read   = 1;
                mem_to_reg = 1;
                alu_src    = 1;  // base + offset
                alu_ctrl   = 4'b0000; // ADD
            end

            S_TYPE: begin
                mem_write = 1;
                alu_src   = 1;
                alu_ctrl  = 4'b0000; // ADD for address calc
            end

            B_TYPE: begin
                branch   = 1;
                alu_ctrl = 4'b1000; // SLT - result[0]=1 means rs1 < rs2 (signed)
            end

            JAL: begin
                reg_write = 1;
                jump      = 1;
            end

            JALR: begin
                reg_write = 1;
                alu_src   = 1;
                jump      = 1;
                alu_ctrl  = 4'b0000;
            end

            LUI: begin
                reg_write = 1;
                alu_src   = 1;
            end

            AUIPC: begin
                reg_write = 1;
            end

            default: ; // NOP
        endcase
    end

endmodule
