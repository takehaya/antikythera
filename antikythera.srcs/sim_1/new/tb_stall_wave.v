`timescale 1ns/1ps
//
// Core1 ストール可視化テストベンチ（波形デモ用）
//
//   プログラム: scripts/testcase/stall_stress.dat
//     両コアが同一アドレスへ書込ループ → メモリ競合で Core1 が繰り返しストールする。
//
//   波形で見るべき信号:
//     uut.clk / uut.core0_dmem_req / uut.core1_dmem_req / uut.core1_stall
//     uut.cpu_core0.PC / uut.cpu_core1.PC
//   読み方: 両 dmem_req が同時に 1 → core1_stall=1 → その間 Core1 の PC が止まり、
//           Core0(優先)の PC だけ進む。ストール解除後に Core1 が再開する。
//
//   コンソールにもストール開始/解除と総ストールサイクルを出す。VCDも出力。
//
module tb_stall_wave;

    parameter CLK = 10;
    parameter RUN_CYCLES = 120;

    reg clk = 0, reset = 1;
    integer cycle = 0;
    integer stall_cycles = 0;
    reg c1s_prev = 1'b0;
    wire [31:0] d00, d01, d02, d03, d10, d11, d12, d13;

    MultiCoreCPU #(
        .MEM_FILE("scripts/testcase/stall_stress.dat")
    ) uut (
        .clk(clk), .reset(reset),
        .debug_regs_core0_0(d00), .debug_regs_core0_1(d01),
        .debug_regs_core0_2(d02), .debug_regs_core0_3(d03),
        .debug_regs_core1_0(d10), .debug_regs_core1_1(d11),
        .debug_regs_core1_2(d12), .debug_regs_core1_3(d13)
    );

    always #(CLK/2) clk = ~clk;

    initial begin
        // 波形ダンプ（iverilog用 / Vivado xsim でも有効）
        $dumpfile("build/stall_wave.vcd");
        $dumpvars(0, uut);
        #(CLK*3) reset = 0;
    end

    always @(posedge clk) if (!reset) begin
        cycle = cycle + 1;
        if (uut.core1_stall) stall_cycles = stall_cycles + 1;

        if (!c1s_prev && uut.core1_stall)
            $display("[cyc %0d] Core1 STALL 開始  PC1=0x%h  (core0_req=%b core1_req=%b)",
                     cycle, uut.cpu_core1.PC, uut.core0_dmem_req, uut.core1_dmem_req);
        if (c1s_prev && !uut.core1_stall)
            $display("[cyc %0d] Core1 STALL 解除  PC1=0x%h", cycle, uut.cpu_core1.PC);
        c1s_prev <= uut.core1_stall;

        if (cycle >= RUN_CYCLES) begin
            $display("---- %0d サイクル実行。Core1 総ストール = %0d サイクル ----", cycle, stall_cycles);
            $display("波形: build/stall_wave.vcd（Vivadoでは run_xsim_wave.sh でWDB生成）");
            $finish;
        end
    end

endmodule
