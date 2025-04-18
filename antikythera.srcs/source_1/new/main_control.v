`timescale 1ns/1ps
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
    output reg [2:0] ALUOp // 3bit
);

    // Opcode 定義 (6bit)
    localparam OPC_RTYPE = 6'b000000;
    localparam OPC_ADDI  = 6'b001000;
    localparam OPC_ANDI  = 6'b001100;
    localparam OPC_ORI   = 6'b001101;
    localparam OPC_SLTI  = 6'b001010;
    localparam OPC_LUI   = 6'b001111;
    localparam OPC_LW    = 6'b100011;
    localparam OPC_SW    = 6'b101011;
    localparam OPC_BEQ   = 6'b000100;
    localparam OPC_J     = 6'b000010;

    // ALUOp コード (3bit)
    localparam ALU_ADD = 3'b000;   // 加算・アドレス計算
    localparam ALU_SUB = 3'b001;   // 差分 (beq)
    localparam ALU_RTY = 3'b010;   // R‑type → functで決定
    localparam ALU_AND = 3'b011;   // andi
    localparam ALU_OR  = 3'b100;   // ori
    localparam ALU_SLT = 3'b101;   // slti
    localparam ALU_LUI = 3'b110;   // lui (imm<<16)

    always @(*) begin
        // デフォルトは NOP
        RegDst   = 0;
        ALUSrc   = 0;
        MemtoReg = 0;
        RegWrite = 0;
        MemRead  = 0;
        MemWrite = 0;
        Branch   = 0;
        Jump     = 0;
        ALUOp    = ALU_ADD;

        case (Op)
            // R‑type
            OPC_RTYPE: begin
                RegDst   = 1;
                RegWrite = 1;
                ALUOp    = ALU_RTY;
            end
            // 即値演算
            OPC_ADDI: begin
                ALUSrc   = 1;
                RegWrite = 1;
                ALUOp    = ALU_ADD;
            end
            OPC_ANDI: begin
                ALUSrc   = 1;
                RegWrite = 1;
                ALUOp    = ALU_AND;
            end
            OPC_ORI: begin
                ALUSrc   = 1;
                RegWrite = 1;
                ALUOp    = ALU_OR;
            end
            OPC_SLTI: begin
                ALUSrc   = 1;
                RegWrite = 1;
                ALUOp    = ALU_SLT;
            end
            OPC_LUI: begin
                ALUSrc   = 1;
                RegWrite = 1;
                ALUOp    = ALU_LUI;
            end
            // メモリアクセス
            OPC_LW: begin
                ALUSrc   = 1;
                MemtoReg = 1;
                RegWrite = 1;
                MemRead  = 1;
                ALUOp    = ALU_ADD;
            end
            OPC_SW: begin
                ALUSrc   = 1;
                MemWrite = 1;
                ALUOp    = ALU_ADD;
            end
            // 分岐・ジャンプ
            OPC_BEQ: begin
                Branch   = 1;
                ALUOp    = ALU_SUB;
            end
            OPC_J: begin
                Jump     = 1;
            end
            // 既定 (NOP)
            default: ;   // すでに NOP をセット済み
        endcase
    end
endmodule
