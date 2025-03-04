`timescale 1ns/1ps

module tb_MainControl;

reg  [5:0] Op;
wire RegDst, ALUSrc, MemtoReg, RegWrite;
wire MemRead, MemWrite, Branch, Jump;
wire [1:0] ALUOp;

MainControl uut (
    .Op(Op),
    .RegDst(RegDst),
    .ALUSrc(ALUSrc),
    .MemtoReg(MemtoReg),
    .RegWrite(RegWrite),
    .MemRead(MemRead),
    .MemWrite(MemWrite),
    .Branch(Branch),
    .Jump(Jump),
    .ALUOp(ALUOp)
);

initial begin
    $monitor($time, 
            "Op=%b => RegDst=%b ALUSrc=%b MemtoReg=%b RegWrite=%b | MemRead=%b MemWrite=%b Branch=%b Jump=%b ALUOp=%b",
             Op, RegDst, ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, Jump, ALUOp);

    // R-type opcode=000000
    Op = 6'b000000; #10;

    // lw=100011(35dec)
    Op = 6'b100011; #10;

    // sw=101011(43dec)
    Op = 6'b101011; #10;

    // beq=000100(4dec)
    Op = 6'b000100; #10;

    // j=000010(2dec)
    Op = 6'b000010; #10;

    // undefined: nop
    Op = 6'b111111; #10;

    #10;
    $stop;
end

endmodule
