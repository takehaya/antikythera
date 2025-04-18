
`timescale 1ns/1ps
module InstructionMemory(
    input  [31:0] PC,
    output [31:0] Instruction
);
    reg [31:0] mem [0:1023];
    wire [9:0] wordAddr = PC[11:2]; // 4byte aligned
    assign Instruction = mem[wordAddr];
    initial begin
        $readmemh("memfile_I.dat", mem);
    end
endmodule
