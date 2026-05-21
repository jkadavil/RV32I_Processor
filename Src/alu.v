`timescale 1ns / 1ps
module alu (
    input  [31:0] a, b,
    input  [3:0]  ctrl,
    output reg [31:0] result,
    output        zero        // used by BEQ/BNE
);
    // ctrl encoding
    // 0000 = ADD
    // 0001 = SUB
    // 0010 = AND
    // 0011 = OR
    // 0100 = XOR
    // 0101 = SLL  (shift left logical)
    // 0110 = SRL  (shift right logical)
    // 0111 = SRA  (shift right arithmetic)
    // 1000 = SLT  (signed less than)
    // 1001 = SLTU (unsigned less than)

    assign zero = (result == 32'b0);

    always @(*) begin
        case (ctrl)
            4'b0000: result = a + b;
            4'b0001: result = a - b;
            4'b0010: result = a & b;
            4'b0011: result = a | b;
            4'b0100: result = a ^ b;
            4'b0101: result = a << b[4:0];
            4'b0110: result = a >> b[4:0];
            4'b0111: result = $signed(a) >>> b[4:0];
            4'b1000: result = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
            4'b1001: result = (a < b)                   ? 32'b1 : 32'b0;
            default: result = 32'b0;
        endcase
    end

endmodule
