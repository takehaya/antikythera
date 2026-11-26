`timescale 1ns/1ps
//
// マルチコア動作デモ 自己検証テストベンチ
//
//   プログラム: scripts/testcase/multicore_demo.dat
//     2コアが同一プログラムを実行し、CORE_ID で別々の領域に並列に書き込む。
//       Core0 → 0x1100..0x1110 = {0,1,2,3,4}
//       Core1 → 0x1200..0x1210 = {256,257,258,259,260}  (上位バイト=CORE_ID)
//       完了フラグ: Core0→0x2000, Core1→0x2004
//
//   「マルチコアが動く」証明:
//     1コアだけならその ID 側の領域しか埋まらない。両領域が正しく埋まっている =
//     2つのコアが各自の CORE_ID 分岐を並列に実行した、ということ。
//
//   出力: "RESULT: PASS/FAIL" と "CYCLES=" / "SYNC=" (両フラグが立ったサイクル)。
//
module tb_multicore_demo;

    parameter CLK         = 10;
    parameter MAX_CYCLES  = 3000;   // ウォッチドッグ（未完了をPASSと誤認しない）

    localparam CORE0_W = 1088;  // 0x1100
    localparam CORE1_W = 1152;  // 0x1200
    localparam FLAG0_W = 2048;  // 0x2000
    localparam FLAG1_W = 2049;  // 0x2004

    reg clk = 0, reset = 1;
    integer i, err = 0, cycle = 0;
    integer sync_cycle = -1;
    reg [31:0] EXP0 [0:4];
    reg [31:0] EXP1 [0:4];

    wire [31:0] d00, d01, d02, d03, d10, d11, d12, d13;

    MultiCoreCPU #(
        .MEM_FILE("scripts/testcase/multicore_demo.dat")
    ) uut (
        .clk(clk), .reset(reset),
        .debug_regs_core0_0(d00), .debug_regs_core0_1(d01),
        .debug_regs_core0_2(d02), .debug_regs_core0_3(d03),
        .debug_regs_core1_0(d10), .debug_regs_core1_1(d11),
        .debug_regs_core1_2(d12), .debug_regs_core1_3(d13)
    );

    always #(CLK/2) clk = ~clk;

    initial begin
        for (i = 0; i < 5; i = i + 1) begin
            EXP0[i] = i;            // Core0: {0,1,2,3,4}
            EXP1[i] = 256 + i;      // Core1: {256,...,260}
        end
        if ($test$plusargs("DUMP")) begin
            $dumpfile("build/multicore_demo.vcd");
            $dumpvars(0, uut);
        end
        #(CLK*3) reset = 0;
    end

    always @(posedge clk) if (!reset) begin
        cycle = cycle + 1;

        // 両コアの完了フラグが揃ったサイクル = 同期完了 → 照合して終了
        if (sync_cycle < 0 &&
            uut.mem_arbiter.data_memory.mem[FLAG0_W] == 32'd1 &&
            uut.mem_arbiter.data_memory.mem[FLAG1_W] == 32'd1) begin
            sync_cycle = cycle;
            check_and_finish;
        end

        if (cycle >= MAX_CYCLES) begin
            $display("TIMEOUT: 両コアの完了フラグが %0d サイクル以内に揃わなかった (f0=%0d f1=%0d)",
                     cycle,
                     uut.mem_arbiter.data_memory.mem[FLAG0_W],
                     uut.mem_arbiter.data_memory.mem[FLAG1_W]);
            err = err + 1;
            finish_report;
        end
    end

    task check_and_finish;
        begin
            // Core0 の領域 0x1100 = {0,1,2,3,4}
            for (i = 0; i < 5; i = i + 1)
                if (uut.mem_arbiter.data_memory.mem[CORE0_W + i] !== EXP0[i]) begin
                    $display("FAIL core0_mem[%0d] exp=%0d got=%0d",
                             i, EXP0[i], uut.mem_arbiter.data_memory.mem[CORE0_W + i]);
                    err = err + 1;
                end
            // Core1 の領域 0x1200 = {256,...,260}
            for (i = 0; i < 5; i = i + 1)
                if (uut.mem_arbiter.data_memory.mem[CORE1_W + i] !== EXP1[i]) begin
                    $display("FAIL core1_mem[%0d] exp=%0d got=%0d",
                             i, EXP1[i], uut.mem_arbiter.data_memory.mem[CORE1_W + i]);
                    err = err + 1;
                end
            // CORE_ID が正しく配布されているか（両方0の結線ミス検出）: $s0=regs[16]
            if (uut.cpu_core0.rf.regs[16] !== 32'd0) begin
                $display("FAIL core0 $s0 exp=0 got=%0d", uut.cpu_core0.rf.regs[16]); err = err + 1;
            end
            if (uut.cpu_core1.rf.regs[16] !== 32'd1) begin
                $display("FAIL core1 $s0 exp=1 got=%0d", uut.cpu_core1.rf.regs[16]); err = err + 1;
            end
            finish_report;
        end
    endtask

    task finish_report;
        begin
            $display("Core0 region 0x1100 = {%0d,%0d,%0d,%0d,%0d}",
                     uut.mem_arbiter.data_memory.mem[CORE0_W+0], uut.mem_arbiter.data_memory.mem[CORE0_W+1],
                     uut.mem_arbiter.data_memory.mem[CORE0_W+2], uut.mem_arbiter.data_memory.mem[CORE0_W+3],
                     uut.mem_arbiter.data_memory.mem[CORE0_W+4]);
            $display("Core1 region 0x1200 = {%0d,%0d,%0d,%0d,%0d}",
                     uut.mem_arbiter.data_memory.mem[CORE1_W+0], uut.mem_arbiter.data_memory.mem[CORE1_W+1],
                     uut.mem_arbiter.data_memory.mem[CORE1_W+2], uut.mem_arbiter.data_memory.mem[CORE1_W+3],
                     uut.mem_arbiter.data_memory.mem[CORE1_W+4]);
            $display("CYCLES=%0d SYNC=%0d", cycle, sync_cycle);
            if (err == 0) $display("RESULT: PASS (multicore demo: 2 cores ran in parallel)");
            else          $display("RESULT: FAIL (multicore demo, %0d errors)", err);
            if (err == 0) $finish;
            else          $fatal(1, "multicore demo FAILED");
        end
    endtask

endmodule
