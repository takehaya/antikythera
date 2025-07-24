`timescale 1ns/1ps
module InstructionMemory(
    input  [31:0] PC,
    output [31:0] Instruction
);
    reg [31:0] mem [0:1023];
    wire [9:0] wordAddr = PC[11:2]; // 4byte aligned
    assign Instruction = mem[wordAddr];
    initial begin
        // まず全体を0で初期化
        integer i;
        for (i = 0; i < 1024; i = i + 1) begin
            mem[i] = 32'h00000000;
        end
        
        // メモリファイルから読み込み（失敗時は手動初期化）
        $readmemh("memfile_I.dat", mem);
        
        // 読み込み確認とフォールバック
        if (mem[0] === 32'hxxxxxxxx) begin
            $display("WARNING: memfile_I.dat読み込み失敗。手動初期化を実行します。");
            // 簡単なテストプログラム（無限ループ）
            mem[0] = 32'h08000000;  // j 0 (無限ループ)
            mem[1] = 32'h00000000;  // nop
        end else begin
            $display("INFO: memfile_I.dat正常に読み込まれました。");
        end
    end
endmodule
