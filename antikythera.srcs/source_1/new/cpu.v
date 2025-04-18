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

    // 命令メモリ
    wire [31:0] Instruction;
    InstructionMemory imem (
        .PC         (PC),
        .Instruction(Instruction)
    );
    
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
    wire [2:0] ALUOp; //3bit
    
    // 制御ユニット
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

    // 即値拡張（Sign / Zero / LUI）
    // SignExtender: 16bit immediate -> 32bit signed immediate
    // ZeroExtender: 16bit immediate -> 32bit zero-extended immediate
    // LuiExtender: 16bit immediate -> 32bit immediate << 16
    wire [31:0] SignImm, ZeroImm, LuiImm;
    SignExtender  se (.in(imm), .out(SignImm));
    ZeroExtender  ze (.in(imm), .out(ZeroImm));
    assign LuiImm = {imm, 16'h0000};
    // opcode に応じて即値を選択
    function automatic [31:0] select_imm;
        input [5:0] op;
        begin
            case (op)
                6'b001100, 6'b001101: select_imm = ZeroImm; // ANDI, ORI
                6'b001111:            select_imm = LuiImm;  // LUI
                default:              select_imm = SignImm; // ADDI, SLTI, etc.
            endcase
        end
    endfunction

    // ALU制御 & ALU本体
    wire [3:0] ALUControl;
    ALUControl aluCtrl(
        .ALUOp(ALUOp),
        .funct(funct),
        .ALUControl(ALUControl)
    );
    
    // ALUの入力2を選択するMUX
    // ALUの入力2は、レジスタからの読み出しか即値かを選択
    wire [31:0] ImmVal = select_imm(opcode);

    wire [31:0] ALUInput2 = (ALUSrc) ? ImmVal : regData2;
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
    DataMemory dmem (
        .clk      (clk),
        .MemWrite (MemWrite),
        .MemRead  (MemRead),
        .Address  (ALUResult),
        .WriteData(regData2),
        .ReadData (memReadData)
    );

    // 書き込みデータのMUX
    assign WriteData = (MemtoReg) ? memReadData : ALUResult;

    // beq/bne 系分岐が取られたときの遷移先
    wire [31:0] PCBranch = PCplus4 + (SignImm << 2);

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
