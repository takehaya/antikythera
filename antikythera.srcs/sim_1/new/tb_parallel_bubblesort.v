`timescale 1ns/1ps
//
// 並列バブルソートの自己検証テストベンチ（雛形：Step6 完成後に使用）
//
//  前提プログラム: scripts/testcase/parallel_bubblesort.dat（Step6 で作成）
//    規約:
//      - 各コアは $s0(=regs[16]) に CORE_ID を保持する
//      - Core0 完了で 0x2000 に 1、Core1 完了で 0x2004 に 1 を書く
//      - マージ結果は 0x2100 から10語
//      - 全処理完了後に 0x2200 へ 0xDEAD を書く（完了マーカー）
//
//  検証内容:
//    - マージ結果 0x2100(word2112) の10語が {0..9} か（!== で x/z も FAIL）
//    - 単調非減少（ソート済み）か
//    - CORE_ID 配布（Core0 $s0=0 / Core1 $s0=1。両方0の結線ミス検出）
//    - 完了サイクル & フェーズ別内訳（sort/merge）を計測 → スピードアップ比較用
//    - デッドロック検出: 上限サイクル & ライブロック(両PC不変)で必ず $finish
//
//  注意: get_mem_val は input[9:0] で 0x2100 を低位アドレスにエイリアスするため使わず、
//        uut.mem_arbiter.data_memory.mem[word] を直接階層参照する。
//
module tb_parallel_bubblesort;

    parameter CLK         = 10;
    parameter MAX_CYCLES  = 5000;   // 設計memo想定 ~230 の20倍以上
    parameter STUCK_LIMIT = 300;    // 両PC不変がこのサイクル続いたらライブロック確定

    localparam MERGE_W = 2112;  // 0x2100  マージ結果
    localparam FLAG0_W = 2048;  // 0x2000  Core0完了フラグ
    localparam FLAG1_W = 2049;  // 0x2004  Core1完了フラグ
    localparam DONE_W  = 2176;  // 0x2200  完了マーカー(0xDEAD)

    reg clk = 0, reset = 1;
    integer i, err = 0, cycle = 0, stuck = 0;
    integer sort_done = -1, merge_done = -1;
    reg [31:0] EXPECTED [0:9];
    reg [31:0] pc0_prev, pc1_prev;

    wire [31:0] d00, d01, d02, d03, d10, d11, d12, d13;

    MultiCoreCPU #(
        .MEM_FILE("scripts/testcase/parallel_bubblesort.dat")
    ) uut (
        .clk(clk), .reset(reset),
        .debug_regs_core0_0(d00), .debug_regs_core0_1(d01),
        .debug_regs_core0_2(d02), .debug_regs_core0_3(d03),
        .debug_regs_core1_0(d10), .debug_regs_core1_1(d11),
        .debug_regs_core1_2(d12), .debug_regs_core1_3(d13)
    );

    always #(CLK/2) clk = ~clk;

    initial begin
        for (i = 0; i < 10; i = i + 1) EXPECTED[i] = i;
        if ($test$plusargs("DUMP")) begin
            $dumpfile("build/par_full.vcd");
            $dumpvars(0, uut);
        end
        #(CLK*3) reset = 0;
    end

    always @(posedge clk) if (!reset) begin
        cycle = cycle + 1;

        // ソート完了（両フラグ立ち）サイクルを記録
        if (sort_done < 0 &&
            uut.mem_arbiter.data_memory.mem[FLAG0_W] == 32'd1 &&
            uut.mem_arbiter.data_memory.mem[FLAG1_W] == 32'd1)
            sort_done = cycle;

        // ライブロック検出（両PCが動かない）
        if (uut.cpu_core0.PC == pc0_prev && uut.cpu_core1.PC == pc1_prev)
            stuck = stuck + 1;
        else
            stuck = 0;
        pc0_prev = uut.cpu_core0.PC;
        pc1_prev = uut.cpu_core1.PC;

        if (stuck > STUCK_LIMIT) begin
            $display("TIMEOUT(livelock) cyc=%0d pc0=%h pc1=%h f0=%0d f1=%0d st1=%b",
                     cycle, uut.cpu_core0.PC, uut.cpu_core1.PC,
                     uut.mem_arbiter.data_memory.mem[FLAG0_W],
                     uut.mem_arbiter.data_memory.mem[FLAG1_W], uut.core1_stall);
            err = err + 1;
            finish_report;
        end

        if (cycle >= MAX_CYCLES) begin
            $display("TIMEOUT(maxcyc) cyc=%0d", cycle);
            err = err + 1;
            finish_report;
        end

        // 完了マーカー検出 → 照合して終了
        if (merge_done < 0 &&
            uut.mem_arbiter.data_memory.mem[DONE_W] == 32'hDEAD) begin
            merge_done = cycle;
            check_and_finish;
        end
    end

    task check_and_finish;
        begin
            for (i = 0; i < 10; i = i + 1) begin
                if (uut.mem_arbiter.data_memory.mem[MERGE_W + i] !== EXPECTED[i]) begin
                    $display("FAIL merge[%0d] exp=%0d got=%0d",
                             i, EXPECTED[i], uut.mem_arbiter.data_memory.mem[MERGE_W + i]);
                    err = err + 1;
                end
                if (i > 0 && uut.mem_arbiter.data_memory.mem[MERGE_W + i] <
                             uut.mem_arbiter.data_memory.mem[MERGE_W + i - 1]) begin
                    $display("FAIL not sorted at %0d", i);
                    err = err + 1;
                end
            end
            // CORE_ID 配布（並列プログラムは $s0=regs[16] にID保持の規約）
            if (uut.cpu_core0.rf.regs[16] !== 32'd0) begin
                $display("FAIL core0 $s0 exp=0 got=%0d", uut.cpu_core0.rf.regs[16]);
                err = err + 1;
            end
            if (uut.cpu_core1.rf.regs[16] !== 32'd1) begin
                $display("FAIL core1 $s0 exp=1 got=%0d", uut.cpu_core1.rf.regs[16]);
                err = err + 1;
            end
            finish_report;
        end
    endtask

    task finish_report;
        begin
            $display("CYCLES=%0d SORT=%0d MERGE=%0d", cycle, sort_done, merge_done);
            if (err == 0) $display("RESULT: PASS (parallel bubblesort)");
            else          $display("RESULT: FAIL (parallel bubblesort, %0d errors)", err);
            if (err == 0) $finish;
            else          $fatal(1, "parallel bubblesort FAILED");
        end
    endtask

endmodule
