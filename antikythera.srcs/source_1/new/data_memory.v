`timescale 1ns/1ps

// Memory configuration
`define MEM_SIZE 4096  // Memory size in words (16KB) - 共有メモリ領域(0x2000+)をカバー

module DataMemory(
    input         clk,
    input         MemWrite,
    input         MemRead,
    input  [31:0] Address,
    input  [31:0] WriteData,
    output [31:0] ReadData
);
    // メモリ配列（0x1100番地までアクセス可能にするため）
    reg [31:0] mem [0:`MEM_SIZE-1];
    // ワードアドレス（32bit アドレスの 4 バイト境界アライン版）
    wire [11:0] wordAddr = Address[13:2];

    // 書き込み処理処理
    always @(posedge clk) begin
        if (MemWrite) mem[wordAddr] <= WriteData;
    end

    // read data(read mode有効じゃない場合はxを返す)
    assign ReadData = MemRead ? mem[wordAddr] : 32'hxxxx_xxxx;

    integer i;
    initial begin
        for (i=0; i<`MEM_SIZE; i=i+1) mem[i] = 32'h0;
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
