`timescale 1ns/1ps
//
// 単一コア・バブルソートの自己検証テストベンチ（ベースライン）
//
//  - MEM_FILE 注入でプログラムを明示ロード（グローバル ./memfile_I.dat に依存しない）
//  - 結果配列(0x1100 から10語)を期待値 {0..9} と自動照合
//  - 結果が初めてソート済みになったサイクルを完了サイクルとして計測（並列版との比較用ベースライン）
//  - 機械可読な "RESULT: PASS/FAIL" と "CYCLES=" を出力、失敗時は $fatal で非ゼロ終了
//
module tb_single_bubblesort;

    parameter CLK        = 10;
    parameter MAX_CYCLES = 3000;          // ウォッチドッグ（未完了をPASSと誤認しない）
    localparam RESULT_W  = 1088;          // 0x1100 / 4 = word 1088

    reg clk = 0;
    reg reset = 1;
    integer i, err = 0, cycle = 0;
    integer done_cycle = -1;
    reg match;
    reg [31:0] EXPECTED [0:9];
    wire [31:0] t0, t1, t2, t3;

    // 命令プログラムを明示注入（vvp の実行 cwd = repo root から解決）
    SingleCycleCPU #(
        .MEM_FILE("scripts/testcase/single_bubblesort.dat")
    ) uut (
        .clk(clk), .reset(reset),
        .reg_t0(t0), .reg_t1(t1), .reg_t2(t2), .reg_t3(t3)
    );

    always #(CLK/2) clk = ~clk;

    initial begin
        for (i = 0; i < 10; i = i + 1) EXPECTED[i] = i;   // 期待値 {0,1,...,9}
        if ($test$plusargs("DUMP")) begin
            $dumpfile("build/single_bubble.vcd");
            $dumpvars(0, uut);
        end
        #(CLK*3) reset = 0;
    end

    always @(posedge clk) if (!reset) begin
        cycle = cycle + 1;

        // 完了検出: 結果配列が初めて {0..9} に一致したサイクルを記録
        if (done_cycle < 0) begin
            match = 1'b1;
            for (i = 0; i < 10; i = i + 1)
                if (uut.dmem.mem[RESULT_W + i] !== EXPECTED[i]) match = 1'b0;
            if (match) begin
                done_cycle = cycle;
                check_and_finish;
            end
        end

        // ウォッチドッグ
        if (cycle >= MAX_CYCLES) begin
            $display("TIMEOUT: single bubblesort did not complete in %0d cycles", cycle);
            err = err + 1;
            finish_report;
        end
    end

    task check_and_finish;
        begin
            for (i = 0; i < 10; i = i + 1) begin
                if (uut.dmem.mem[RESULT_W + i] !== EXPECTED[i]) begin
                    $display("FAIL result[%0d] exp=%0d got=%0d",
                             i, EXPECTED[i], uut.dmem.mem[RESULT_W + i]);
                    err = err + 1;
                end
                if (i > 0 && uut.dmem.mem[RESULT_W + i] < uut.dmem.mem[RESULT_W + i - 1]) begin
                    $display("FAIL not sorted at %0d", i);
                    err = err + 1;
                end
            end
            finish_report;
        end
    endtask

    task finish_report;
        begin
            $display("CYCLES=%0d", done_cycle);
            if (err == 0) $display("RESULT: PASS (single bubblesort)");
            else          $display("RESULT: FAIL (single bubblesort, %0d errors)", err);
            if (err == 0) $finish;
            else          $fatal(1, "single bubblesort FAILED");
        end
    endtask

endmodule
