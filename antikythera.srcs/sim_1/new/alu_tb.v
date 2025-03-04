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

module tb_ALU;
reg  [31:0] A, B;
reg  [3:0]  ALUControl;
wire [31:0] ALUResult;
wire        Zero;

ALU uut (
    .A(A),
    .B(B),
    .ALUControl(ALUControl),
    .ALUResult(ALUResult),
    .Zero(Zero)
);

initial begin
    $monitor($time, " ALUControl=%b, A=%d, B=%d, ALUResult=%d, Zero=%b",
             ALUControl, A, B, ALUResult, Zero);

    // 1) AND
    A=32'h0000_00FF; B=32'h0000_FF00; ALUControl=4'b0000; #10; // AND => 0x0000_0000
    // 2) OR
    ALUControl=4'b0001; #10; // => 0x0000_FFFF
    // 3) ADD
    A=32'd10; B=32'd5;   ALUControl=4'b0010; #10; // => 15
    // 4) SUB
    ALUControl=4'b0110; #10; // => 5
    // 5) SLT
    A=32'd3; B=32'd7; ALUControl=4'b0111; #10; // => 1 (3<7)
    // 6) SUB => Zero?
    A=32'd100; B=32'd100; ALUControl=4'b0110; #10; // => 0, Zero=1

    #10;
end

endmodule
