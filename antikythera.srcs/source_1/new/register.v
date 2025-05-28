`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2025 04:39:45 PM
// Design Name: 
// Module Name: register
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


module Register(
    input         clk,
    input         RegWrite,
    input  [4:0]  ReadReg1,
    input  [4:0]  ReadReg2,
    input  [4:0]  WriteReg,
    input  [31:0] WriteData,
    output [31:0] ReadData1,
    output [31:0] ReadData2,

    // レジスタ出力（観察用）
    output [31:0] reg_t0,
    output [31:0] reg_t1,
    output [31:0] reg_t2,
    output [31:0] reg_t3
);

reg [31:0] regs[31:0]; // 32本の32bitレジスタ

// 同期書き込み(posedge clkで動かす)
always @(posedge clk) begin
    if(RegWrite) begin
        if(WriteReg != 0) // $zeroを書き換えないようにするなら
            regs[WriteReg] <= WriteData;
    end
end

// 非同期読み出し
// assign ReadData1 = regs[ReadReg1];
// assign ReadData2 = regs[ReadReg2];
assign ReadData1 = (RegWrite && (WriteReg == ReadReg1) && (WriteReg != 0)) ? WriteData : regs[ReadReg1];
assign ReadData2 = (RegWrite && (WriteReg == ReadReg2) && (WriteReg != 0)) ? WriteData : regs[ReadReg2];

// レジスタ出力（観察用）
assign reg_t0 = regs[8];
assign reg_t1 = regs[9];
assign reg_t2 = regs[10];
assign reg_t3 = regs[11];

//シミュレーター用の初期化
integer i;
initial begin
    // レジスタを0で初期化
    for(i=0; i<32; i=i+1) begin
        regs[i] = 32'h0;
    end
end

endmodule
