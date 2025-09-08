`timescale 1ns / 1ps

module tb_MultiCoreCPU;

    // パラメータ
    parameter CLK_PERIOD = 10; // 100MHz
    
    // テスト信号
    reg clk;
    reg reset;
    
    // デバッグ出力
    wire [31:0] debug_regs_core0 [3:0];
    wire [31:0] debug_regs_core1 [3:0];

    // テスト対象のインスタンス化
    MultiCoreCPU uut (
        .clk(clk),
        .reset(reset),
        .debug_regs_core0(debug_regs_core0),
        .debug_regs_core1(debug_regs_core1)
    );

    // クロック生成
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // テストシーケンス
    initial begin
        // 入力を初期化
        reset = 1;
        
        // グローバルリセット待機
        #(CLK_PERIOD * 5);
        
        // リセット解除
        reset = 0;
        $display("Dual Core CPU Test Started");
        
        // コア状態をモニタ
        fork
            monitor_core_states();
            monitor_memory_arbitration();
        join_none
        
        // 適当な時間シミュレーション実行
        #(CLK_PERIOD * 500);
        
        $display("Test completed");
        $finish;
    end

    // コア状態を観察するモニタタスク
    task monitor_core_states;
        begin
            forever begin
                @(posedge clk);
                #1; // 信号が安定するまで少し待つ
                
                if (!reset) begin
                    $display("Time: %0t", $time);
                    $display("  Core 0: t0=%h t1=%h t2=%h t3=%h", 
                             debug_regs_core0[0], debug_regs_core0[1], 
                             debug_regs_core0[2], debug_regs_core0[3]);
                    $display("  Core 1: t0=%h t1=%h t2=%h t3=%h", 
                             debug_regs_core1[0], debug_regs_core1[1], 
                             debug_regs_core1[2], debug_regs_core1[3]);
                    $display("  ---");
                end
                
                // モニタ間の遅延を追加
                repeat(10) @(posedge clk);
            end
        end
    endtask

    // メモリ調停をモニタするタスク
    task monitor_memory_arbitration;
        begin
            forever begin
                @(posedge clk);
                #1; // 信号が安定するまで少し待つ
                
                // メモリアクセス競合とストールをモニタ
                if (uut.core0_stall) begin
                    $display("Core 0 STALLED due to memory conflict");
                end
                
                if (uut.core1_stall) begin
                    $display("Core 1 STALLED due to memory conflict");
                end
                
                // メモリリクエストをモニタ
                if (uut.core0_dmem_req || uut.core0_imem_req) begin
                    $display("Core 0 Memory Request - DMEM: %b IMEM: %b", 
                             uut.core0_dmem_req, uut.core0_imem_req);
                end
                
                if (uut.core1_dmem_req || uut.core1_imem_req) begin
                    $display("Core 1 Memory Request - DMEM: %b IMEM: %b", 
                             uut.core1_dmem_req, uut.core1_imem_req);
                end
            end
        end
    endtask
    
endmodule