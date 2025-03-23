`timescale 1ns / 1ps

module SingleCycleCPU(
    input clk,
    input reset,

    output [31:0] reg_t0,
    output [31:0] reg_t1,
    output [31:0] reg_t2,
    output [31:0] reg_t3
);
    // プログラムカウンタ
    reg [31:0] PC;

    // 次PC計算用
    wire [31:0] PCplus4  = PC + 4;
    wire [31:0] SignImm;
    wire [31:0] PCBranch = PCplus4 + (SignImm << 2);  // beq用(PC+4 + signExtImm<<2)

    // 命令取得
    wire [31:0] Instruction;
    
    // 命令各フィールド
    wire [5:0] opcode = Instruction[31:26];
    wire [4:0] rs     = Instruction[25:21];
    wire [4:0] rt     = Instruction[20:16];
    wire [4:0] rd     = Instruction[15:11];
    wire [5:0] funct  = Instruction[5:0];
    wire [15:0] imm   = Instruction[15:0];
    wire [25:0] jumpAddr = Instruction[25:0];

    // 制御信号
    wire RegDst, ALUSrc, MemtoReg, RegWrite;
    wire MemRead, MemWrite, Branch, Jump;
    wire [1:0] ALUOp;

    MainControl mainCtrl(
        .Op(opcode),
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

    // レジスタファイル
    wire [31:0] regData1, regData2;
    wire [4:0]  WriteReg = (RegDst) ? rd : rt;  // R-typeならrd, lwならrtなど
    wire [31:0] WriteData; // メモリ読み込み結果 or ALU結果

    Register rf(
        .clk(clk),
        .RegWrite(RegWrite),
        .ReadReg1(rs),
        .ReadReg2(rt),
        .WriteReg(WriteReg),
        .WriteData(WriteData),
        .ReadData1(regData1),
        .ReadData2(regData2),

        // 観察用
        .reg_t0(reg_t0),
        .reg_t1(reg_t1),
        .reg_t2(reg_t2),
        .reg_t3(reg_t3)
    );

    // 符号拡張
    SignExtender se(
        .in(imm),
        .out(SignImm)
    );

    // ALU制御 & ALU本体
    wire [3:0] ALUControl;
    ALUControl aluCtrl(
        .ALUOp(ALUOp),
        .funct(funct),
        .ALUControl(ALUControl)
    );

    wire [31:0] ALUInput2 = (ALUSrc) ? SignImm : regData2;
    wire [31:0] ALUResult;
    wire        Zero;

    ALU alu(
        .A(regData1),
        .B(ALUInput2),
        .ALUControl(ALUControl),
        .ALUResult(ALUResult),
        .Zero(Zero)
    );

    // データメモリ
    wire [31:0] memReadData;
    Memory memory(
        .clk(clk),
        .PC(PC),
        .Instruction(Instruction),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .Address(ALUResult),
        .WriteData(regData2),
        .ReadData(memReadData)
    );

    // 書き込みデータのMUX
    assign WriteData = (MemtoReg) ? memReadData : ALUResult;

    // Branch判定
    wire PCSrc = Branch & Zero;
    // Jumpアドレス生成: {PCplus4[31:28], jumpAddr, 2'b00}
    wire [31:0] jumpTarget = { PCplus4[31:28], jumpAddr, 2'b00 };

    // 次PC選択
    wire [31:0] PCnext = (Jump) ? jumpTarget :
                         (PCSrc) ? PCBranch : 
                                   PCplus4;

    // PC更新
    always @(posedge clk or posedge reset) begin
        if(reset) PC <= 0;
        else      PC <= PCnext;
    end

endmodule
