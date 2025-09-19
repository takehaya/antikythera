`timescale 1ns/1ps
module InstructionMemory #(
    parameter MEM_FILE = "memfile_I.dat"  // デフォルトファイル名
)(
    input  [31:0] PC,
    output [31:0] Instruction
);
    reg [31:0] mem [0:1023];
    wire [9:0] wordAddr = PC[11:2]; // 4byte aligned
    assign Instruction = mem[wordAddr];
    initial begin: initdata
        // まず全体を0で初期化
        integer i;
        for (i = 0; i < 1024; i = i + 1) begin
            mem[i] = 32'h00000000;
        end
        
        // パラメータ指定されたメモリファイルから読み込み
        $readmemh(MEM_FILE, mem);
        
        // 読み込み確認とフォールバック
        if (mem[0] === 32'hxxxxxxxx) begin
            $display("WARNING: %s読み込み失敗。手動初期化を実行します。", MEM_FILE);
            // 簡単なテストプログラム（無限ループ）
            mem[0] = 32'h08000000;  // j 0 (無限ループ)
            mem[1] = 32'h00000000;  // nop
        end else begin
            $display("INFO: %s正常に読み込まれました。", MEM_FILE);
        end
    end
endmodule
