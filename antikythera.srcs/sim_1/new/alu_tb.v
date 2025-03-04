`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2025 02:37:21 PM
// Design Name: 
// Module Name: alu_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module tb_alu;
    // テストベンチ内部で使う信号を宣言
    // ALUの入力は reg, 出力は wire として定義
    reg  [7:0] A;
    reg  [7:0] B;
    reg  [3:0] ALU_Sel;
    wire [7:0] ALU_Out;
    wire       CarryOut;

    // テスト対象の ALU モジュールをインスタンス化
    alu uut (
        .A       (A),
        .B       (B),
        .ALU_Sel (ALU_Sel),
        .ALU_Out (ALU_Out),
        .CarryOut(CarryOut)
    );

    // シミュレーションの進行を管理する initial ブロック
    initial begin
        // ヘッダ表示
        $display("=== Start Simulation ===");
        $display(" time |   A   |   B   | ALU_Sel | ALU_Out | CarryOut ");

        // 波形や値の変化をモニタする => 変化があるたびに自動で表示される（便利）
        $monitor("%4dns | %2h | %2h |   %1h    |   %2h    |   %1b", 
                 $time, A, B, ALU_Sel, ALU_Out, CarryOut);

        // 初期値設定
        A       = 8'h0A;  // 0x0A = 10
        B       = 8'h02;  // 0x02 = 2
        ALU_Sel = 4'h0;   // 0

        // ALU_Sel を 0〜15 まで変化させて各演算をテスト
        repeat (16) begin
            #10;               // 10ns 待機
            ALU_Sel = ALU_Sel + 1;  // opcodeを1ずつ増やす
        end

        // 追加テスト - 入力変更して再度チェック
        #10;
        A = 8'hF6;   // 0xF6
        B = 8'h0A;   // 0x0A
        ALU_Sel = 4'h0;
        #10;

        $display("=== End Simulation ===");
        $finish;
    end

endmodule
