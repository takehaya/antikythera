`timescale 1ns/1ps
module DataMemory(
    input         clk,
    input         MemWrite,
    input         MemRead,
    input  [31:0] Address,
    input  [31:0] WriteData,
    output [31:0] ReadData
);
    // 2048 ワード（8KB）メモリ（0x1100番地までアクセス可能にするため）
    reg [31:0] mem [0:2047];
    // ワードアドレス（32bit アドレスの 4 バイト境界アライン版）
    wire [10:0] wordAddr = Address[12:2];

    // 書き込み処理処理
    always @(posedge clk) begin
        if (MemWrite) mem[wordAddr] <= WriteData;
    end

    // read data(read mode有効じゃない場合はxを返す)
    assign ReadData = MemRead ? mem[wordAddr] : 32'hxxxx_xxxx;

    integer i;
    initial begin
        for (i=0; i<2048; i=i+1) mem[i] = 32'h0;
    end

    // メモリの値を取得する関数
    // テストベンチなどで使用するための関数
    function [31:0] get_mem_val;
        input [9:0] word_addr;
        begin
            get_mem_val = mem[word_addr];
        end
    endfunction
endmodule
