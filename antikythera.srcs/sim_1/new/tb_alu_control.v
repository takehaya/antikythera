`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2025 04:34:22 PM
// Design Name: 
// Module Name: tb_alu_control
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


`timescale 1ns/1ps

module tb_ALUControl;

reg  [1:0] ALUOp;
reg  [5:0] funct;
wire [3:0] ALUControl;

ALUControl uut (
    .ALUOp(ALUOp),
    .funct(funct),
    .ALUControl(ALUControl)
);

initial begin
    $monitor($time, " ALUOp=%b, funct=%b => ALUControl=%b", ALUOp, funct, ALUControl);

    // テスト: lw/sw (ALUOp=00 => add)
    ALUOp = 2'b00; funct = 6'bxxxxxx; #10; // => ALUControl=0010 (ADD)

    // テスト: beq (ALUOp=01 => sub)
    ALUOp = 2'b01; funct = 6'bxxxxxx; #10; // => ALUControl=0110 (SUB)

    // テスト: R-type (ALUOp=10) => functで決定
    ALUOp = 2'b10;

    // add: funct=100000
    funct = 6'b100000; #10;
    // sub: funct=100010
    funct = 6'b100010; #10;
    // and: funct=100100
    funct = 6'b100100; #10;
    // or : funct=100101
    funct = 6'b100101; #10;
    // slt: funct=101010
    funct = 6'b101010; #10;

    // それ以外
    funct = 6'b111111; #10; // default => ADD

    #10;
end

endmodule
