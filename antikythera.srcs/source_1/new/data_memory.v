`timescale 1ns/1ps
module DataMemory(
    input         clk,
    input         MemWrite,
    input         MemRead,
    input  [31:0] Address,
    input  [31:0] WriteData,
    output [31:0] ReadData
);
    reg [31:0] mem [0:1023];
    wire [9:0] wordAddr = Address[11:2];

    always @(posedge clk) begin
        if (MemWrite) mem[wordAddr] <= WriteData;
    end

    // read data(read mode有効じゃない場合はxを返す)
    assign ReadData = MemRead ? mem[wordAddr] : 32'hxxxx_xxxx;

    integer i;
    initial begin
        for (i=0; i<1024; i=i+1) mem[i] = 32'h0;
    end
endmodule
