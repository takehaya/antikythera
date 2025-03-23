`timescale 1ns/1ps

module Memory(
    input         clk,
    // 命令メモリ
    input  [31:0] PC,          // PC値
    output [31:0] Instruction, // 命令

    // データメモリ
    input         MemWrite,
    input         MemRead,
    input  [31:0] Address,
    input  [31:0] WriteData,
    output [31:0] ReadData
);

reg [31:0] InstrMem[0:1023];
reg [31:0] DataMem [0:1023];

// 命令読み出し (PCを4バイト単位で使用)
wire [9:0] instrAddr = PC[11:2];
assign Instruction = InstrMem[instrAddr];

// データメモリ読み書き
wire [9:0] dataAddr = Address[11:2];  // 4バイト単位
reg  [31:0] dataOut;

always @(posedge clk) begin
    if(MemWrite) begin
        DataMem[dataAddr] <= WriteData;
    end
    dataOut <= (MemRead) ? DataMem[dataAddr] : 32'h0;
end

assign ReadData = dataOut;

// テスト用初期化
integer i;
initial begin
    $readmemh("memfile_I.dat", InstrMem);

    // データメモリ初期化
    for(i=0; i<1024; i=i+1) begin
        DataMem[i] = 32'h0;
    end
end

endmodule
