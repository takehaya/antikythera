`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2025 04:39:45 PM
// Design Name: 
// Module Name: main_control
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


// 命令のopcode(6bit) を入力にとり、各制御信号を出す
module MainControl(
    input  [5:0] Op,
    output reg       RegDst,
    output reg       ALUSrc,
    output reg       MemtoReg,
    output reg       RegWrite,
    output reg       MemRead,
    output reg       MemWrite,
    output reg       Branch,
    output reg       Jump,
    output reg [1:0] ALUOp
);

// 命令のopcode (10進表記)
// R形式: 0, lw:35(0x23), sw:43(0x2B), beq:4, jump:2
// (書籍に合わせる: R=000000, lw=100011, sw=101011, beq=000100, j=000010)

always @(*) begin
    case(Op)
        6'b000000: begin // R-type
            RegDst   = 1;
            ALUSrc   = 0;
            MemtoReg = 0;
            RegWrite = 1;
            MemRead  = 0;
            MemWrite = 0;
            Branch   = 0;
            Jump     = 0;
            ALUOp    = 2'b10;
        end
        6'b100011: begin // lw
            RegDst   = 0;
            ALUSrc   = 1;
            MemtoReg = 1;
            RegWrite = 1;
            MemRead  = 1;
            MemWrite = 0;
            Branch   = 0;
            Jump     = 0;
            ALUOp    = 2'b00;
        end
        6'b101011: begin // sw
            RegDst   = 0; // don't care
            ALUSrc   = 1;
            MemtoReg = 0; // don't care
            RegWrite = 0;
            MemRead  = 0;
            MemWrite = 1;
            Branch   = 0;
            Jump     = 0;
            ALUOp    = 2'b00;
        end
        6'b000100: begin // beq
            RegDst   = 0; // don't care
            ALUSrc   = 0; // don't care (we usually do SUB with registers)
            MemtoReg = 0; // don't care
            RegWrite = 0;
            MemRead  = 0;
            MemWrite = 0;
            Branch   = 1;
            Jump     = 0;
            ALUOp    = 2'b01;
        end
        6'b000010: begin // jump
            RegDst   = 0; 
            ALUSrc   = 0; 
            MemtoReg = 0; 
            RegWrite = 0;
            MemRead  = 0;
            MemWrite = 0;
            Branch   = 0;
            Jump     = 1; // jump信号をアクティブに
            ALUOp    = 2'b00; // don't care
        end
        default: begin
            // 未定義opcode -> とりあえずNOPにしておく
            RegDst   = 0;
            ALUSrc   = 0;
            MemtoReg = 0;
            RegWrite = 0;
            MemRead  = 0;
            MemWrite = 0;
            Branch   = 0;
            Jump     = 0;
            ALUOp    = 2'b00;
        end
    endcase
end

endmodule
