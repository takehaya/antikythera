`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2025 06:29:29 AM
// Design Name: 
// Module Name: alu
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

module ALU(
    input  [31:0] A,
    input  [31:0] B,
    input  [3:0]  ALUControl,  // 4ビットで操作指定
    output reg [31:0] ALUResult,
    output Zero // 後でbeq命令で使用
);

assign Zero = (ALUResult == 0);

always @(*) begin
    case(ALUControl)
        4'b0000: ALUResult = A & B;    // AND
        4'b0001: ALUResult = A | B;    // OR
        4'b0010: ALUResult = A + B;    // ADD
        4'b0110: ALUResult = A - B;    // SUB
        4'b0111: ALUResult = (A < B) ? 32'd1 : 32'd0; // SLT
        4'b1100: ALUResult = ~(A | B); // NOR (optional)
        // 必要に応じて演算追加
        default: ALUResult = 32'h0;
    endcase
end

endmodule
