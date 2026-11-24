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

    // データメモリの競合検出（命令メモリはデュアルポートなので競合なし）
    // シンプルな優先制御：コア0が常に優先
    wire core0_dmem_grant = core0_dmem_req;
    wire core1_dmem_grant = core1_dmem_req && !core0_dmem_req;

    // ストールロジック：リクエストはあるが許可されない場合にストール
    assign core0_stall = 1'b0;  // コア0は決してストールしない（優先権あり）
    assign core1_stall = (core1_dmem_req && !core1_dmem_grant);  // データメモリ競合時のみストール

    // データメモリインタフェースの多重化
    wire dmem_write_granted = (core0_dmem_grant && core0_dmem_write) ||
                             (core1_dmem_grant && core1_dmem_write);
    wire dmem_read_granted = (core0_dmem_grant && !core0_dmem_write) ||
                            (core1_dmem_grant && !core1_dmem_write);

    wire [31:0] dmem_addr_mux = core0_dmem_grant ? core0_dmem_addr : core1_dmem_addr;
    wire [31:0] dmem_write_data_mux = core0_dmem_grant ? core0_dmem_write_data : core1_dmem_write_data;

    // メモリインスタンス
    wire [31:0] dmem_read_data;
    wire [31:0] rom_data_read;
    wire data_address_is_rom = (dmem_addr_mux < 32'h00001000);
    wire [31:0] shared_read_data = data_address_is_rom ? rom_data_read : dmem_read_data;

    DataMemory data_memory (
        .clk(clk),
        .MemWrite(dmem_write_granted && !data_address_is_rom),
        .MemRead(dmem_read_granted && !data_address_is_rom),
        .Address(dmem_addr_mux),
        .WriteData(dmem_write_data_mux),
        .ReadData(dmem_read_data)
    );

    // 命令メモリ: デュアルポートで各コアに直結（mux不要）
    InstructionMemory #(
        .MEM_FILE(MEM_FILE)
    ) inst_memory (
        .PC0(core0_imem_addr),
        .Instruction0(core0_imem_read_data),
        .PC1(core1_imem_addr),
        .Instruction1(core1_imem_read_data)
    );

    // Read-only ROM data path for cold-boot input copy. Keep the existing
    // independent instruction ports. Physical BRAM mapping is not asserted.
    InstructionMemory #(.MEM_FILE(MEM_FILE)) data_image (
        .PC0(dmem_addr_mux), .Instruction0(rom_data_read),
        .PC1(32'd0), .Instruction1()
    );

    // データメモリ出力の振り分け
    assign core0_dmem_read_data = core0_dmem_grant ? shared_read_data : 32'h0;
    assign core1_dmem_read_data = core1_dmem_grant ? shared_read_data : 32'h0;

endmodule