`timescale 1ns/1ps

module SimpleMemoryArbiter #(
    parameter MEM_FILE = "memfile_I.dat"  // 命令メモリファイル名
)(
    input clk,
    input reset,
    
    // コア0のメモリリクエスト
    input         core0_dmem_req,
    input         core0_dmem_write,
    input  [31:0] core0_dmem_addr,
    input  [31:0] core0_dmem_write_data,
    output [31:0] core0_dmem_read_data,
    
    input         core0_imem_req,
    input  [31:0] core0_imem_addr,
    output [31:0] core0_imem_read_data,
    
    // コア1のメモリリクエスト
    input         core1_dmem_req,
    input         core1_dmem_write,
    input  [31:0] core1_dmem_addr,
    input  [31:0] core1_dmem_write_data,
    output [31:0] core1_dmem_read_data,
    
    input         core1_imem_req,
    input  [31:0] core1_imem_addr,
    output [31:0] core1_imem_read_data,
    
    // 各コアへのストール出力
    output        core0_stall,
    output        core1_stall
);

    // メモリインスタンス
    wire [31:0] dmem_read_data;
    wire [31:0] imem_read_data;
    
    DataMemory data_memory (
        .clk(clk),
        .MemWrite(dmem_write_granted),
        .MemRead(dmem_read_granted),
        .Address(dmem_addr_mux),
        .WriteData(dmem_write_data_mux),
        .ReadData(dmem_read_data)
    );
    
    InstructionMemory #(
        .MEM_FILE(MEM_FILE)
    ) inst_memory (
        .PC(imem_addr_mux),
        .Instruction(imem_read_data)
    );

    // 競合検出
    wire dmem_conflict = core0_dmem_req && core1_dmem_req;
    wire imem_conflict = core0_imem_req && core1_imem_req;
    
    // シンプルな優先制御：コア0が常に優先
    wire core0_dmem_grant = core0_dmem_req;
    wire core1_dmem_grant = core1_dmem_req && !core0_dmem_req;
    
    wire core0_imem_grant = core0_imem_req;
    wire core1_imem_grant = core1_imem_req;  // 命令メモリは常に許可
    
    // ストールロジック：リクエストはあるが許可されない場合にストール
    assign core0_stall = 1'b0;  // コア0は決してストールしない（優先権あり）
    assign core1_stall = (core1_dmem_req && !core1_dmem_grant)? 1'b1: 1'b0;  // データメモリ競合時のみストール
    
    // メモリインタフェースの多重化
    wire dmem_write_granted = (core0_dmem_grant && core0_dmem_write) || 
                             (core1_dmem_grant && core1_dmem_write);
    wire dmem_read_granted = (core0_dmem_grant && !core0_dmem_write) || 
                            (core1_dmem_grant && !core1_dmem_write);
    
    wire [31:0] dmem_addr_mux = core0_dmem_grant ? core0_dmem_addr : core1_dmem_addr;
    wire [31:0] dmem_write_data_mux = core0_dmem_grant ? core0_dmem_write_data : core1_dmem_write_data;
    
    wire [31:0] imem_addr_mux = core0_imem_grant ? core0_imem_addr : core1_imem_addr;
    
    // 出力データの振り分け
    assign core0_dmem_read_data = core0_dmem_grant ? dmem_read_data : 32'h0;
    assign core1_dmem_read_data = core1_dmem_grant ? dmem_read_data : 32'h0;
    
    assign core0_imem_read_data = core0_imem_grant ? imem_read_data : 32'h0;
    assign core1_imem_read_data = core1_imem_grant ? imem_read_data : 32'h0;

endmodule