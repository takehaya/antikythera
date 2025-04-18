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

// endmodule
module ALUControl(
    input      [2:0] ALUOp,
    input      [5:0] funct,
    output reg [3:0] ALUControl
);

always @(*) begin
    case(ALUOp)
        3'b000: ALUControl = 4'b0010;       // ADD
        3'b001: ALUControl = 4'b0110;       // SUB
        3'b010: begin                       // R-type
            case(funct)
                6'b100000: ALUControl = 4'b0010; // ADD
                6'b100010: ALUControl = 4'b0110; // SUB
                6'b100100: ALUControl = 4'b0000; // AND
                6'b100101: ALUControl = 4'b0001; // OR
                6'b101010: ALUControl = 4'b0111; // SLT
                6'b100111: ALUControl = 4'b1100; // NOR
                default  : ALUControl = 4'b0010;
            endcase
        end
        3'b011: ALUControl = 4'b0000;       // ANDI
        3'b100: ALUControl = 4'b0001;       // ORI
        3'b101: ALUControl = 4'b0111;       // SLTI
        3'b110: ALUControl = 4'b0011;       // LUI (→ ALUResult = imm<<16 とするなら 0003 を新設)
        default: ALUControl = 4'b0010;
    endcase
end
endmodule
