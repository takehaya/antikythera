`timescale 1ns / 1ps

// メモリ境界の定義
`define INST_MEM_BOUNDARY 32'h1000  // 命令メモリ: 0x0000-0x0FFF, データメモリ: 0x1000+

module SimpleCPUWithMemInterface(
    input clk,
    input reset,
    input stall,  // メモリ調停器からのストール信号
    
    // 調停器へのデータメモリインタフェース
    output reg    dmem_req,
    output reg    dmem_write,
    output reg [31:0] dmem_addr,
    output reg [31:0] dmem_write_data,
    input  [31:0] dmem_read_data,
    
    // 調停器への命令メモリインタフェース
    output reg    imem_req,
    output reg [31:0] imem_addr,
    input  [31:0] imem_read_data,

    output [31:0] reg_t0,
    output [31:0] reg_t1,
    output [31:0] reg_t2,
    output [31:0] reg_t3
);
    // プログラムカウンタ
    reg [31:0] PC;

    // 次PC計算用
    wire [31:0] PCplus4  = PC + 4;

    // 命令メモリアクセス
    always @(*) begin
        imem_req = 1'b1;  // 常に命令を要求
        imem_addr = PC;
    end
    
    wire [31:0] Instruction = imem_read_data;
    
    // 命令各フィールド
    wire [5:0] opcode = Instruction[31:26];
    wire [4:0] rs     = Instruction[25:21];
    wire [4:0] rt     = Instruction[20:16];
    wire [4:0] rd     = Instruction[15:11];
    wire [5:0] funct  = Instruction[5:0];
    wire [15:0] imm   = Instruction[15:0];
    wire [25:0] jumpAddr = Instruction[25:0];
    
    // shiftのための変数
    wire [4:0] shamt = Instruction[10:6];
    wire       funct_bit2 = Instruction[2]; 
    
    // 制御信号
    wire RegDst, ALUSrc, MemtoReg, RegWrite;
    wire MemRead, MemWrite;
    
    // ストール制御用の中間信号
    wire RegWriteGated = RegWrite && !stall;
    wire Branch, BranchNot;
    wire Jump, JumpReg, Link;
    wire [2:0] ALUOp; //3bit
    
    // 制御ユニット
    MainControl mainCtrl(
        .Op(opcode),
        .Funct(funct),
        .RegDst(RegDst),
        .ALUSrc(ALUSrc),
        .MemtoReg(MemtoReg),
        .RegWrite(RegWrite),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .Branch(Branch),
        .BranchNot (BranchNot),
        .Jump(Jump),
        .JumpReg(JumpReg),
        .Link (Link),
        .ALUOp(ALUOp)
    );

    // レジスタファイル
    wire [31:0] regData1, regData2;
    // Link が立っているときは固定で $ra (=31) へ書き込む
    wire [4:0] WriteReg = Link   ? 5'd31 :
                          RegDst ? rd    :
                                   rt;
    wire [31:0] WriteData; // メモリ読み込み結果 or ALU結果

    Register rf(
        .clk(clk),
        .RegWrite(RegWriteGated),  // ストール中はレジスタ書き込み無効
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
    wire [31:0] SignImm, ZeroImm, LuiImm;
    SignExtender  se (.in(imm), .out(SignImm));
    ZeroExtender  ze (.in(imm), .out(ZeroImm));
    assign LuiImm = {imm, 16'h0000};

    // ALU制御 & ALU本体
    wire [3:0] ALUControl;
    ALUControl aluCtrl(
        .ALUOp(ALUOp),
        .funct(funct),
        .ALUControl(ALUControl)
    );
    
    // ALUの入力2を選択するMUX
    reg [31:0] ImmVal;
    always @(*) begin
        case (opcode)
            6'b001100, 6'b001101: ImmVal = ZeroImm; // ANDI, ORI
            6'b001111:            ImmVal = LuiImm;  // LUI
            default:              ImmVal = SignImm; // ADDI, SLTI, etc.
        endcase
    end

    wire [31:0] ALUInput2 = (ALUSrc) ? ImmVal : regData2;
    wire [31:0] ALUResult;
    wire        ZeroFlag;

    ALU alu(
        .A(regData1),
        .B(ALUInput2),
        .shamt(shamt),
        .funct_bit2 (funct_bit2),
        .ALUControl(ALUControl),
        .ALUResult(ALUResult),
        .Zero(ZeroFlag)
    );

    // データメモリアクセス
    always @(*) begin
        if (MemRead || MemWrite) begin
            dmem_req = 1'b1;
            dmem_write = MemWrite;
            dmem_addr = ALUResult;
            dmem_write_data = regData2;
        end else begin
            dmem_req = 1'b0;
            dmem_write = 1'b0;
            dmem_addr = 32'h0;
            dmem_write_data = 32'h0;
        end
    end

    // 統合メモリアクセス: lw命令で命令メモリもアクセス可能にする
    // (この機能は簡略化のため省略、必要に応じて追加)
    wire [31:0] unifiedMemReadData = dmem_read_data;

    // 書き込みデータのMUX
    assign WriteData = Link ? PCplus4 :
                       MemtoReg ? unifiedMemReadData :
                                   ALUResult;

    // beq/bne 系分岐が取られたときの遷移先
    wire [31:0] PCBranch = PCplus4 + (SignImm << 2);

    // Branch判定
    wire takeBranch =
           (Branch     &&  ZeroFlag) ||   // beq
           (BranchNot  && !ZeroFlag);     // bne

    // Jumpアドレス生成: {PCplus4[31:28], jumpAddr, 2'b00}
    wire [31:0] jumpTarget = { PCplus4[31:28], jumpAddr, 2'b00 };

    // 次PC選択
    wire [31:0] PCnext = JumpReg ? regData1 :
                         Jump    ? jumpTarget :
                         takeBranch ? PCBranch :
                                      PCplus4;

    // PC更新（ストール時は更新しない）
    always @(posedge clk or posedge reset) begin
        if(reset) 
            PC <= 0;
        else if (!stall)  // ストール中でない場合のみPC更新
            PC <= PCnext;
        // ストール中はPCを維持
    end

endmodule