`timescale 1ns/1ps

module tb_RegisterFile;

reg         clk;
reg         RegWrite;
reg  [4:0]  ReadReg1, ReadReg2, WriteReg;
reg  [31:0] WriteData;
wire [31:0] ReadData1, ReadData2;

RegisterFile uut (
    .clk(clk),
    .RegWrite(RegWrite),
    .ReadReg1(ReadReg1),
    .ReadReg2(ReadReg2),
    .WriteReg(WriteReg),
    .WriteData(WriteData),
    .ReadData1(ReadData1),
    .ReadData2(ReadData2)
);

// クロック生成(10ns周期, posedge +5ns, negedge +5nsで1周期)
always #5 clk = ~clk;

initial begin
    clk = 0; RegWrite = 0;
    ReadReg1=0; ReadReg2=0; WriteReg=0; WriteData=0;

    // Write Reg1=5 => 32'hAAAA_BBBB
    #10;
    WriteReg = 5; WriteData = 32'hAAAA_BBBB; RegWrite=1;
    #10; // posedgeクロックで書き込み
    RegWrite=0;

    // Read from Reg1=5 => expecting 0xAAAA_BBBB
    ReadReg1 = 5; ReadReg2 = 0; #10;

    // Write Reg2=1 => 32'h1234_5678
    WriteReg = 1; WriteData = 32'h1234_5678; RegWrite=1;
    #10; 
    RegWrite=0;

    // Read from Reg1=1 => expecting 0x1234_5678
    ReadReg1 = 1; #10;

    // Attempt write to $zero (reg0)
    WriteReg=0; WriteData=32'hFFFF_FFFF; RegWrite=1; #10;
    RegWrite=0;

    // Read from $zero => still 0
    ReadReg1=0; #10;

    $stop;
end

initial begin
    $monitor($time, " clk=%b, R1=%d->%h, R2=%d->%h, WReg=%d=%h, RegWrite=%b",
             clk, ReadReg1, ReadData1, ReadReg2, ReadData2, WriteReg, WriteData, RegWrite);
end

endmodule
