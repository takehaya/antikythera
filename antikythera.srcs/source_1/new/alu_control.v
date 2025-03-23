`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2025 04:27:49 PM
// Design Name: 
// Module Name: alu_control
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


module ALUControl(
    input      [1:0] ALUOp,     // MainControlerから ALUOp(2bit) を受け取る
    input      [5:0] funct,     // R形式命令の funct フィールド (命令[5:0])
    output reg [3:0] ALUControl
);
    // funct フィールド (R形式命令) で使われる値の例
    localparam FUNCT_ADD = 6'b100000;
    localparam FUNCT_SUB = 6'b100010;
    localparam FUNCT_AND = 6'b100100;
    localparam FUNCT_OR  = 6'b100101;
    localparam FUNCT_SLT = 6'b101010;
    localparam FUNCT_NOR = 6'b100111; // optional

    always @(*) begin
        case(ALUOp)
            2'b00: ALUControl = 4'b0010; // lw, sw -> ADD
            2'b01: ALUControl = 4'b0110; // beq    -> SUB
            2'b10: begin
                // R形式 -> functで操作判定
                case(funct)
                    FUNCT_ADD: ALUControl = 4'b0010; // ADD
                    FUNCT_SUB: ALUControl = 4'b0110; // SUB
                    FUNCT_AND: ALUControl = 4'b0000; // AND
                    FUNCT_OR : ALUControl = 4'b0001; // OR
                    FUNCT_SLT: ALUControl = 4'b0111; // SLT
                    FUNCT_NOR: ALUControl = 4'b1100; // NOR
                    default:   ALUControl = 4'b0010; // とりあえずADD
                endcase
            end
            2'b11: ALUControl = 4'b0001; // ori → or (imm)
            default: ALUControl = 4'b0010; // 他 -> ADD
        endcase
    end

endmodule
