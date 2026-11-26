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

`timescale 1ns/1ps
module ALUControl (
    input      [2:0] ALUOp,
    input      [5:0] funct,
    output reg [3:0] ALUControl
);

localparam [3:0] ALU_AND = 4'b0000,
                 ALU_OR  = 4'b0001,
                 ALU_ADD = 4'b0010,
                 ALU_SUB = 4'b0110,
                 ALU_SLT = 4'b0111,
                 ALU_LUI = 4'b0011,
                 ALU_SLL = 4'b1000,
                 ALU_SRL = 4'b1001,
                 ALU_SRA = 4'b1010,
                 ALU_NOR = 4'b1100;

always @(*) begin
    case (ALUOp)
        3'b000: ALUControl = ALU_ADD;            // default: ADD
        3'b001: ALUControl = ALU_SUB;            // BEQ
        3'b010:                                   // -- R-type 
            case (funct)
                6'b100000: ALUControl = ALU_ADD;  // ADD
                6'b100001: ALUControl = ALU_ADD;  // ADDU
                6'b100010: ALUControl = ALU_SUB;  // SUB
                6'b100011: ALUControl = ALU_SUB;  // SUBU
                6'b100100: ALUControl = ALU_AND;  // AND
                6'b100101: ALUControl = ALU_OR;   // OR
                6'b101010: ALUControl = ALU_SLT;  // SLT
                6'b100111: ALUControl = ALU_NOR;  // NOR
                6'b000000: ALUControl = ALU_SLL;  // SLL
                6'b000010: ALUControl = ALU_SRL;  // SRL
                6'b000011: ALUControl = ALU_SRA;  // SRA
                default  : ALUControl = ALU_ADD;  // else: ADD
            endcase
        3'b011: ALUControl = ALU_AND;            // ANDI
        3'b100: ALUControl = ALU_OR;             // ORI
        3'b101: ALUControl = ALU_SLT;            // SLTI
        3'b110: ALUControl = ALU_LUI;            // LUI
        default: ALUControl = ALU_ADD;
    endcase
end
endmodule