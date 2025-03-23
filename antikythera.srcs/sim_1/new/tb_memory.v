`timescale 1ns/1ps

module tb_Memory;

reg         clk;
reg  [31:0] PC;
wire [31:0] Instruction;

reg         MemWrite, MemRead;
reg  [31:0] Address, WriteData;
wire [31:0] ReadData;

Memory uut (
    .clk(clk),
    // 命令メモリ
    .PC(PC),
    .Instruction(Instruction),
    // データメモリ
    .MemWrite(MemWrite),
    .MemRead(MemRead),
    .Address(Address),
    .WriteData(WriteData),
    .ReadData(ReadData)
);

// クロック生成
// 10ns周期のクロック（100MHz）
always #5 clk = ~clk;

initial begin
    clk = 0;
    PC  = 0;
    MemWrite=0; MemRead=0;
    Address=0; WriteData=0;
    $display("InstrMem[0]=%h", uut.InstrMem[0]);

    // 命令メモリを読み出し (PC=0, PC=4, ...)
    // instactionの信号が切り替わるかが見える
    #10; PC=32'h00000000;
    #10; PC=32'h00000004;
    #10; PC=32'h00000008;

    // データメモリへの書き込み
    // posedge clkでWriteDataがMem[Address(4)]に書き込まれる
    MemWrite=1; MemRead=0;
    Address=32'h00000010;  // (word index=4 if shifted)
    WriteData=32'hDEAD_BEEF; #10; 
    MemWrite=0;

    // データメモリの読み出し
    // posedge clkでMem[Address(4)]がReadDataに読み出される
    MemWrite=0;
    MemRead=1; 
    #10; // => ReadData should be 0xDEAD_BEEF
    MemRead=0;

    #20;
    $stop;
end

initial begin
    $monitor($time, " PC=%h Instr=%h, MemWrite=%b MemRead=%b Address=%h => ReadData=%h",
             PC, Instruction, MemWrite, MemRead, Address, ReadData);
end

endmodule
