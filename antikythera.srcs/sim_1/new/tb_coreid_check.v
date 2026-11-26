`timescale 1ns/1ps
//
// デュアルコア CORE_ID 識別の自己検証テストベンチ
//
//  プログラム core_id_test: lw $t0,0(0x3000) で自コアIDを取得、$t1 にコピー。
//  Core0 は CORE_ID=0、Core1 は CORE_ID=1 を $t0/$t1 に持つはず。
//  → 2コアが別IDで独立動作している（設計7ステップ Step1/3/5）ことの回帰チェック。
//
//  機械可読な "RESULT: PASS/FAIL" を出力、失敗時は $fatal で非ゼロ終了。
//
module tb_coreid_check;

    parameter CLK = 10;
    parameter CHECK_CYCLE = 30;   // 3命令でspin到達するので十分すぎるマージン

    reg clk = 0;
    reg reset = 1;
    integer cycle = 0, err = 0;
    reg checked = 1'b0;
    wire [31:0] c00, c01, c02, c03, c10, c11, c12, c13;

    MultiCoreCPU #(
        .MEM_FILE("scripts/testcase/core_id_test.dat")
    ) uut (
        .clk(clk), .reset(reset),
        .debug_regs_core0_0(c00), .debug_regs_core0_1(c01),
        .debug_regs_core0_2(c02), .debug_regs_core0_3(c03),
        .debug_regs_core1_0(c10), .debug_regs_core1_1(c11),
        .debug_regs_core1_2(c12), .debug_regs_core1_3(c13)
    );

    always #(CLK/2) clk = ~clk;

    initial begin
        if ($test$plusargs("DUMP")) begin
            $dumpfile("build/coreid.vcd");
            $dumpvars(0, uut);
        end
        #(CLK*3) reset = 0;
    end

    always @(posedge clk) if (!reset) begin
        cycle = cycle + 1;
        if (!checked && cycle >= CHECK_CYCLE) begin
            checked = 1'b1;
            // Core0 → ID 0, Core1 → ID 1 ($t0=reg8, $t1=reg9)
            if (c00 !== 32'd0) begin $display("FAIL core0 t0 exp=0 got=%0d", c00); err = err + 1; end
            if (c01 !== 32'd0) begin $display("FAIL core0 t1 exp=0 got=%0d", c01); err = err + 1; end
            if (c10 !== 32'd1) begin $display("FAIL core1 t0 exp=1 got=%0d", c10); err = err + 1; end
            if (c11 !== 32'd1) begin $display("FAIL core1 t1 exp=1 got=%0d", c11); err = err + 1; end
            $display("Core0 t0=%0d t1=%0d | Core1 t0=%0d t1=%0d", c00, c01, c10, c11);
            if (err == 0) $display("RESULT: PASS (coreid)");
            else          $display("RESULT: FAIL (coreid, %0d errors)", err);
            if (err == 0) $finish;
            else          $fatal(1, "coreid FAILED");
        end
    end

endmodule
