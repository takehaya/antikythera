`timescale 1ns / 1ps

module tb_StallVerification;

    // パラメータ
    parameter CLK_PERIOD = 10;
    parameter TEST_CYCLES = 1000;
    
    // テスト信号
    reg clk;
    reg reset;
    
    // デバッグ出力（フラット化）
    wire [31:0] debug_regs_core0_0, debug_regs_core0_1, debug_regs_core0_2, debug_regs_core0_3;
    wire [31:0] debug_regs_core1_0, debug_regs_core1_1, debug_regs_core1_2, debug_regs_core1_3;
    
    // 統計カウンタ
    reg [31:0] cycle_count;
    reg [31:0] stall_count;
    reg [31:0] conflict_count;
    
    // ストール検証用の変数
    reg [31:0] core0_pc_prev, core1_pc_prev;
    reg core1_stall_prev;
    reg stall_test_passed;
    reg pc_advance_test_passed;

    // テスト設定（使用するメモリファイルを指定）
    parameter TEST_PROGRAM = "simple_stall_test.dat";  // ストール検証用テストプログラム
    
    // テスト対象
    MultiCoreCPU #(
        .MEM_FILE(TEST_PROGRAM)
    ) uut (
        .clk(clk),
        .reset(reset),
        .debug_regs_core0_0(debug_regs_core0_0),
        .debug_regs_core0_1(debug_regs_core0_1),
        .debug_regs_core0_2(debug_regs_core0_2),
        .debug_regs_core0_3(debug_regs_core0_3),
        .debug_regs_core1_0(debug_regs_core1_0),
        .debug_regs_core1_1(debug_regs_core1_1),
        .debug_regs_core1_2(debug_regs_core1_2),
        .debug_regs_core1_3(debug_regs_core1_3)
    );

    // クロック生成
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // メインテストシーケンス
    initial begin
        // 初期化
        reset = 1;
        cycle_count = 0;
        stall_count = 0;
        conflict_count = 0;
        stall_test_passed = 1'b1;  // 初期値はPASS（エラー検出時にFAILに変更）
        pc_advance_test_passed = 1'b1;
        
        $display("=== Stall Verification Test ===");
        $display("Using program file: %s", TEST_PROGRAM);
        $display("Test duration: %0d cycles", TEST_CYCLES);
        $display("=============================");
        
        // リセット解除
        #(CLK_PERIOD * 5);
        reset = 0;
        
        // 指定サイクル実行
        #(CLK_PERIOD * TEST_CYCLES);
        
        // 結果表示
        show_results();
        
        $display("=== Test Completed ===");
        $finish;
    end
    
    // 監視用のalways block
    always @(posedge clk) begin
        if (!reset) begin
            cycle_count <= cycle_count + 1;
            
            // 50サイクルごとに状態表示
            if (cycle_count % 50 == 0 && cycle_count > 0) begin
                $display("[Cycle %0d] Core0: PC=%h t0=%h t1=%h | Core1: PC=%h t0=%h t1=%h", 
                        cycle_count,
                        uut.cpu_core0.PC, debug_regs_core0_0, debug_regs_core0_1,
                        uut.cpu_core1.PC, debug_regs_core1_0, debug_regs_core1_1);
                $display("         Core0_dmem_req=%b Core1_dmem_req=%b Core1_stall=%b",
                        uut.core0_dmem_req, uut.core1_dmem_req, uut.core1_stall);
                if (uut.core1_stall) begin
                    $display("         >>> Core1 is STALLED <<<");
                end
            end
            
            // データメモリ競合とストールの即座表示
            if (uut.core0_dmem_req && uut.core1_dmem_req) begin
                $display("[%0t] DATA MEMORY CONFLICT: Core1 should STALL", $time);
                if (!uut.core1_stall) begin
                    $display("         !!! ERROR: Core1 not stalling during conflict !!!");
                    stall_test_passed = 1'b0;
                end
                conflict_count <= conflict_count + 1;
            end
            
            // ストール統計
            if (uut.core1_stall) begin
                stall_count <= stall_count + 1;
            end
            
            // Core0は決してストールしてはならない
            if (uut.core0_stall) begin
                $display("!!! ERROR: Core0 should never stall (Priority core) !!!");
                stall_test_passed = 1'b0;
            end
            
            // ストール状態変化の検証
            if (!core1_stall_prev && uut.core1_stall) begin
                $display("[%0t] Core1 STALL START - PC=%h", $time, uut.cpu_core1.PC);
            end
            if (core1_stall_prev && !uut.core1_stall) begin
                $display("[%0t] Core1 STALL END - PC=%h", $time, uut.cpu_core1.PC);
            end
            
            // PC更新動作の検証
            if (cycle_count > 1) begin
                // Core1のPC更新検証（ストール時は停止）
                if (uut.core1_stall && (uut.cpu_core1.PC != core1_pc_prev)) begin
                    $display("!!! ERROR: Core1 PC advancing during stall - PC changed from %h to %h !!!", 
                            core1_pc_prev, uut.cpu_core1.PC);
                    pc_advance_test_passed = 1'b0;
                end
                
                if (!uut.core1_stall && (uut.cpu_core1.PC == core1_pc_prev) && 
                    core1_pc_prev != 32'h00000014 && core1_pc_prev != 32'h00000018) begin
                    // ストールしていないのにPCが進まない場合はエラー（ループ命令は除く）
                    $display("!!! ERROR: Core1 PC not advancing when not stalled - stuck at %h !!!", 
                            core1_pc_prev);
                    pc_advance_test_passed = 1'b0;
                end
            end
            
            // 前サイクルの値を保存
            core0_pc_prev <= uut.cpu_core0.PC;
            core1_pc_prev <= uut.cpu_core1.PC;
            core1_stall_prev <= uut.core1_stall;
        end
    end

    // 結果表示
    task show_results;
        begin : show_results_block
            real stall_rate, conflict_rate, efficiency;
            if (cycle_count > 0) begin
                stall_rate = stall_count * 100.0 / cycle_count;
                conflict_rate = conflict_count * 100.0 / cycle_count;
                efficiency = (cycle_count * 2 - stall_count) * 100.0 / (cycle_count * 2);
            end else begin
                stall_rate = 0.0;
                conflict_rate = 0.0;
                efficiency = 0.0;
            end
            
            $display("========== TEST RESULTS ==========");
            $display("Program File: %s", TEST_PROGRAM);
            $display("Execution Summary:");
            $display("  Total Cycles: %0d", cycle_count);
            $display("  Core1 Stalls: %0d (Rate: %0.1f%%)", stall_count, stall_rate);
            $display("  Memory Conflicts: %0d (Rate: %0.1f%%)", conflict_count, conflict_rate);
            $display("  System Efficiency: %0.1f%%", efficiency);
            
            $display("Final Register States:");
            $display("  Core 0: t0=%h t1=%h t2=%h t3=%h",
                     debug_regs_core0_0, debug_regs_core0_1, 
                     debug_regs_core0_2, debug_regs_core0_3);
            $display("  Core 1: t0=%h t1=%h t2=%h t3=%h",
                     debug_regs_core1_0, debug_regs_core1_1, 
                     debug_regs_core1_2, debug_regs_core1_3);
                     
            $display("Stall Verification:");
            $display("  Stall Function Test: %s", stall_test_passed ? "PASSED" : "FAILED");
            $display("  PC Advance Test: %s", pc_advance_test_passed ? "PASSED" : "FAILED");
            
            if (stall_test_passed && pc_advance_test_passed) begin
                $display(">>> OVERALL TEST RESULT: PASSED <<<");
            end else begin
                $display(">>> OVERALL TEST RESULT: FAILED <<<");
            end
            $display("==================================");
        end
    endtask

endmodule
