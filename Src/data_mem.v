`timescale 1ns/1ps
// Byte-addressable data memory with full RV32I width support.
//
// Supported load types  (funct3):
//   000 = LB   sign-extended byte
//   001 = LH   sign-extended halfword
//   010 = LW   full word
//   100 = LBU  zero-extended byte
//   101 = LHU  zero-extended halfword
//
// Supported store types (funct3):
//   000 = SB   byte
//   001 = SH   halfword
//   010 = SW   full word
//
// Memory is word-organised internally; byte enables handle
// sub-word writes so unaddressed bytes are preserved.
(* dont_touch = "yes" *)
module data_mem #(
    parameter DEPTH = 256   // number of 32-bit words
)(
    input         clk,
    input         mem_read,
    input         mem_write,
    input  [2:0]  funct3,
    input  [31:0] addr,
    input  [31:0] wdata,
    output reg [31:0] rdata
);
    (* ram_style = "block" *) reg [31:0] mem [0:DEPTH-1];
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'b0;
    end

    // Word index and byte offset within that word
    wire [29:0] word_addr  = addr[31:2];
    wire [1:0]  byte_off   = addr[1:0];

    // -------------------------------------------------------
    // Synchronous write with byte enables
    // -------------------------------------------------------
    always @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                3'b000: begin // SB - write one byte
                    case (byte_off)
                        2'b00: mem[word_addr][7:0]   <= wdata[7:0];
                        2'b01: mem[word_addr][15:8]  <= wdata[7:0];
                        2'b10: mem[word_addr][23:16] <= wdata[7:0];
                        2'b11: mem[word_addr][31:24] <= wdata[7:0];
                    endcase
                end
                3'b001: begin // SH - write two bytes (halfword)
                    case (byte_off)
                        2'b00: mem[word_addr][15:0]  <= wdata[15:0];
                        2'b10: mem[word_addr][31:16] <= wdata[15:0];
                        default: ; // misaligned - ignore
                    endcase
                end
                3'b010: // SW - write full word
                    mem[word_addr] <= wdata;
                default: ; // undefined funct3 - no write
            endcase
        end
    end

    // -------------------------------------------------------
    // Asynchronous (combinational) read
    // -------------------------------------------------------
    wire [31:0] raw_word = mem[word_addr];

    // Select the right byte/halfword from the fetched word
    wire [7:0]  sel_byte =
        (byte_off == 2'b00) ? raw_word[7:0]   :
        (byte_off == 2'b01) ? raw_word[15:8]  :
        (byte_off == 2'b10) ? raw_word[23:16] :
                              raw_word[31:24];

    wire [15:0] sel_half =
        (byte_off == 2'b00) ? raw_word[15:0]  :
                              raw_word[31:16]; // byte_off == 2'b10

    always @(*) begin
        if (mem_read) begin
            case (funct3)
                3'b000: rdata = {{24{sel_byte[7]}}, sel_byte};        // LB
                3'b001: rdata = {{16{sel_half[15]}}, sel_half};        // LH
                3'b010: rdata = raw_word;                              // LW
                3'b100: rdata = {24'b0, sel_byte};                    // LBU
                3'b101: rdata = {16'b0, sel_half};                    // LHU
                default: rdata = 32'b0;
            endcase
        end else begin
            rdata = 32'b0;
        end
    end

endmodule
