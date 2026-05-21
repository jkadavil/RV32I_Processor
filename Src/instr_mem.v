`timescale 1ns/1ps
(* dont_touch = "yes" *)
module instr_mem #(
    parameter DEPTH = 256
)(
    input  [31:0] addr,
    output [31:0] instr
);
   (* ram_style = "block" *) reg [31:0] mem [0:DEPTH-1];

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'b0;
    end

    assign instr = mem[addr[31:2]];

endmodule
