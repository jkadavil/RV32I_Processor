`timescale 1ns/1ps

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
    always #5 clk = ~clk;

    integer cycle;
    initial cycle = 0;

    always @(posedge clk) begin
        if (rst)
            cycle <= 0;
        else
            cycle <= cycle + 1;
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
        end
        else begin
            $display("CPI          = N/A");
        end

        $display("");
    end
    endtask

    task clear_imem;
    begin
        for (i = 0; i < 256; i = i + 1)
            dut.imem.mem[i] = 0;
    end
    endtask

    task clear_dmem;
    begin
        for (i = 0; i < 256; i = i + 1)
            dut.dmem.mem[i] = 0;
    end
    endtask

    integer fail_count;

    task check;
        input [31:0] got;
        input [31:0] expected;
        input [63:0] label;
    begin
        if (got !== expected) begin
            $display(
                "FAIL %s: got 0x%08X, expected 0x%08X",
                label,
                got,
                expected
            );

            fail_count = fail_count + 1;
        end
        else begin
            $display("PASS %s = %0d", label, got);
        end
    end
    endtask


    initial begin

        $dumpfile("tb_riscv_pipe.vcd");
        $dumpvars(0, tb_riscv_pipe);

        fail_count = 0;


        // ===================================================
        // TEST 1: ALU
        // ===================================================

        $display("\n===== TEST 1: ALU =====");

        $readmemh("test1.mem", dut.imem.mem);

        do_reset;
        run_cycles(40);

        dump_regs();
        print_metrics();


        // ===================================================
        // TEST 2: LOAD / STORE
        // ===================================================

        $display("===== TEST 2: LOAD/STORE =====");

        clear_dmem();

        $readmemh("test2.mem", dut.imem.mem);

        do_reset;
        run_cycles(60);

        dump_regs();
        print_metrics();


        // ===================================================
        // TEST 3: FIBONACCI
        // ===================================================

        $display("===== TEST 3: FIBONACCI =====");

        clear_dmem();

        $readmemh("test3.mem", dut.imem.mem);

        do_reset;
        run_cycles(110);

        dump_regs();
        print_metrics();


        // ===================================================
        // TEST 4: BYTE / HALFWORD MEMORY
        // ===================================================

        $display("===== TEST 4: BYTE/HALFWORD MEM =====");

        clear_dmem();

        $readmemh("test4.mem", dut.imem.mem);

        do_reset;
        run_cycles(80);

        dump_regs();
        print_metrics();

        check(dut.rf.regs[10], 32'hFFFFFFFF, "LB_x10 ");
        check(dut.rf.regs[11], 32'h000000FF, "LBU_x11");
        check(dut.rf.regs[12], 32'h0000007F, "LH_x12 ");
        check(dut.rf.regs[13], 32'h0000007F, "LHU_x13");
        check(dut.rf.regs[14], 32'h0000005A, "LW_x14 ");
        check(dut.rf.regs[15], 32'h0000005B, "ADD_x15");


        // ===================================================
        // TEST 5: BUBBLE SORT
        // ===================================================

        $display("===== TEST 5: BUBBLE SORT =====");

        clear_dmem();

        $readmemh(
            "test5_bubblesort.mem",
            dut.imem.mem
        );

        do_reset;
        run_cycles(500);

        dump_regs();
        print_metrics();

        check(dut.rf.regs[20], 32'd3,  "sort[0]");
        check(dut.rf.regs[21], 32'd11, "sort[1]");
        check(dut.rf.regs[22], 32'd12, "sort[2]");
        check(dut.rf.regs[23], 32'd22, "sort[3]");
        check(dut.rf.regs[24], 32'd25, "sort[4]");
        check(dut.rf.regs[25], 32'd47, "sort[5]");
        check(dut.rf.regs[26], 32'd64, "sort[6]");
        check(dut.rf.regs[27], 32'd90, "sort[7]");


        // ===================================================
        // TEST 6: PIPELINE CORNER CASES
        // ===================================================

        $display(
            "===== TEST 6: PIPELINE CORNER CASES ====="
        );

        clear_imem();
        clear_dmem();

        // Used later by LW tests.
        dut.dmem.mem[0] = 32'd55;

        $readmemh(
            "test6_cornercases.mem",
            dut.imem.mem
        );

        do_reset;
        run_cycles(70);

        dump_regs();
        print_metrics();


        // ---------------------------------------------------
        // Branch verification
        // ---------------------------------------------------

        check(
            dut.rf.regs[10],
            32'd2,
            "BEQ     "
        );

        check(
            dut.rf.regs[11],
            32'd3,
            "BNE_NT  "
        );

        check(
            dut.rf.regs[12],
            32'd4,
            "BNE_T   "
        );

        check(
            dut.rf.regs[13],
            32'd5,
            "BLT     "
        );

        check(
            dut.rf.regs[14],
            32'd6,
            "BGE     "
        );

        check(
            dut.rf.regs[15],
            32'd7,
            "BLTU    "
        );

        check(
            dut.rf.regs[16],
            32'd8,
            "BGEU    "
        );


        // ---------------------------------------------------
        // Wrong-path instructions after jumps must be killed
        // ---------------------------------------------------

        check(
            dut.rf.regs[17],
            32'd0,
            "JAL_KILL"
        );

        check(
            dut.rf.regs[18],
            32'd0,
            "JLR_KILL"
        );


        // ---------------------------------------------------
        // JAL
        //
        // JAL PC = 0x6C
        // Link   = PC + 4 = 0x70
        // ---------------------------------------------------

        check(
            dut.rf.regs[20],
            32'h00000070,
            "JAL_LINK"
        );

        // Instruction at target immediately consumes x20.
        // This checks jump-link forwarding.

        check(
            dut.rf.regs[21],
            32'h00000071,
            "JAL_FWD "
        );


        // ---------------------------------------------------
        // JALR
        //
        // JALR PC = 0x7C
        // Link    = 0x80
        //
        // x5 = 0x85
        //
        // Target:
        // (x5 + 0) & ~1
        // = 0x84
        // ---------------------------------------------------

        check(
            dut.rf.regs[22],
            32'h00000080,
            "JLR_LINK"
        );

        check(
            dut.rf.regs[23],
            32'h00000081,
            "JLR_FWD "
        );


        // ---------------------------------------------------
        // LUI / AUIPC forwarding corner cases
        //
        // These instructions do NOT actually consume rs1.
        // ---------------------------------------------------

        check(
            dut.rf.regs[24],
            32'h12030000,
            "LUI     "
        );

        check(
            dut.rf.regs[25],
            32'h22038094,
            "AUIPC   "
        );


        // ---------------------------------------------------
        // Hazard detection tests
        //
        // First case:
        //
        // LW writes x8.
        //
        // Following ADDI has immediate = 8.
        //
        // instr[24:20] therefore happens to equal 8,
        // but ADDI does NOT use rs2.
        //
        // There should be NO false stall.
        // ---------------------------------------------------

        check(
            dut.rf.regs[26],
            32'd8,
            "NOFALSE "
        );


        // ---------------------------------------------------
        // Real load-use dependency:
        //
        // LW x9,...
        // ADDI x27,x9,1
        //
        // This SHOULD generate exactly one stall.
        // ---------------------------------------------------

        check(
            dut.rf.regs[27],
            32'd56,
            "LOAD_USE"
        );


        // Exactly one real load-use stall should occur.

        check(
            stall_count,
            32'd1,
            "STALLS  "
        );


        // Six taken conditional branches
        // + JAL
        // + JALR
        //
        // = eight redirect events.

        check(
            flush_count,
            32'd8,
            "FLUSHES "
        );


        // ===================================================
        // FINAL RESULT
        // ===================================================

        $display("\n===========================");

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display(
                "FAILURES: %0d",
                fail_count
            );

        $display("===========================\n");

        $finish;
    end

endmodule
