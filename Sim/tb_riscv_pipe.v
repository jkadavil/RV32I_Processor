`timescale 1ns/1ps
// Tests 1-4: functional correctness
// Test 5:    bubble sort - real-world CPI benchmark for reporting

module tb_riscv_pipe;

    reg  clk, rst;
    wire [31:0] pc_out;
    wire [31:0] instr_count;
    wire [31:0] stall_count;
    wire [31:0] flush_count;

    riscv_pipe dut (
        .clk             (clk),
        .rst             (rst),
        .pc_out          (pc_out),
        .instr_count_out (instr_count),
        .stall_count_out (stall_count),
        .flush_count_out (flush_count)
    );

    initial clk = 0;
    always  #5 clk = ~clk;

    integer cycle;
    initial cycle = 0;
    always @(posedge clk) begin
        if (rst) cycle <= 0;
        else     cycle <= cycle + 1;
    end

    task do_reset;
    begin
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
    end
    endtask

    task run_cycles;
        input integer n;
    begin
        repeat (n) @(posedge clk);
    end
    endtask

    integer i;

    task dump_regs;
    begin
        $display("---- Register file ----");
        for (i = 0; i < 32; i = i + 1)
            if (dut.rf.regs[i] !== 0)
                $display("x%-2d = %0d (0x%08X)",
                         i, dut.rf.regs[i], dut.rf.regs[i]);
        $display("-----------------------");
    end
    endtask

    real cpi;
    task print_metrics;
    begin
        $display("Instructions = %0d", instr_count);
        $display("Cycles       = %0d", cycle);
        $display("Stalls       = %0d", stall_count);
        $display("Flushes      = %0d", flush_count);
        if (instr_count != 0) begin
            cpi = $itor(cycle) / $itor(instr_count);
            $display("CPI          = %0.3f", cpi);
        end else
            $display("CPI          = N/A");
        $display("");
    end
    endtask

    task clear_dmem;
    begin
        for (i = 0; i < 256; i = i + 1)
            dut.dmem.mem[i] = 0;
    end
    endtask

    // Simple pass/fail check
    integer fail_count;
    task check;
        input [31:0] got;
        input [31:0] expected;
        input [63:0] label;  // up to 8 ASCII chars
    begin
        if (got !== expected) begin
            $display("FAIL %s: got 0x%08X, expected 0x%08X", label, got, expected);
            fail_count = fail_count + 1;
        end else
            $display("PASS %s = %0d", label, got);
    end
    endtask

    initial begin
        $dumpfile("tb_riscv_pipe.vcd");
        $dumpvars(0, tb_riscv_pipe);
        fail_count = 0;

        // ---------------------------------------------------
        // TEST 1: ALU
        // ---------------------------------------------------
        $display("\n===== TEST 1: ALU =====");
        $readmemh("test1.mem", dut.imem.mem);
        do_reset;
        run_cycles(40);
        dump_regs();
        print_metrics();

        // ---------------------------------------------------
        // TEST 2: LOAD/STORE (word)
        // ---------------------------------------------------
        $display("===== TEST 2: LOAD/STORE =====");
        clear_dmem;
        $readmemh("test2.mem", dut.imem.mem);
        do_reset;
        run_cycles(60);
        dump_regs();
        print_metrics();

        // ---------------------------------------------------
        // TEST 3: FIBONACCI
        // ---------------------------------------------------
        $display("===== TEST 3: FIBONACCI =====");
        clear_dmem;
        $readmemh("test3.mem", dut.imem.mem);
        do_reset;
        run_cycles(110);
        dump_regs();
        print_metrics();

        // ---------------------------------------------------
        // TEST 4: BYTE/HALFWORD MEMORY
        // ---------------------------------------------------
        $display("===== TEST 4: BYTE/HALFWORD MEM =====");
        clear_dmem;
        $readmemh("test4.mem", dut.imem.mem);
        do_reset;
        run_cycles(80);
        dump_regs();
        print_metrics();
        // Automated checks
        check(dut.rf.regs[10], 32'hFFFFFFFF, "LB_x10 ");
        check(dut.rf.regs[11], 32'h000000FF, "LBU_x11");
        check(dut.rf.regs[12], 32'h0000007F, "LH_x12 ");
        check(dut.rf.regs[13], 32'h0000007F, "LHU_x13");
        check(dut.rf.regs[14], 32'h0000005A, "LW_x14 ");
        check(dut.rf.regs[15], 32'h0000005B, "ADD_x15");

        // ---------------------------------------------------
        // TEST 5: BUBBLE SORT  <-- CPI benchmark
        // Input:  [64, 25, 12, 22, 11, 90,  3, 47]
        // Output: [ 3, 11, 12, 22, 25, 47, 64, 90]
        // x20-x27 hold sorted values after completion
        // ---------------------------------------------------
        $display("===== TEST 5: BUBBLE SORT =====");
        clear_dmem;
        $readmemh("test5_bubblesort.mem", dut.imem.mem);
        do_reset;
        run_cycles(500);
        dump_regs();
        print_metrics();
        // Automated checks
        check(dut.rf.regs[20], 32'd3,  "sort[0]");
        check(dut.rf.regs[21], 32'd11, "sort[1]");
        check(dut.rf.regs[22], 32'd12, "sort[2]");
        check(dut.rf.regs[23], 32'd22, "sort[3]");
        check(dut.rf.regs[24], 32'd25, "sort[4]");
        check(dut.rf.regs[25], 32'd47, "sort[5]");
        check(dut.rf.regs[26], 32'd64, "sort[6]");
        check(dut.rf.regs[27], 32'd90, "sort[7]");

        $display("\n===========================");
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("FAILURES: %0d", fail_count);
        $display("===========================\n");

        $finish;
    end

endmodule
