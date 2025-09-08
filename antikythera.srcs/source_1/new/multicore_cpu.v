`timescale 1ns/1ps

module MultiCoreCPU #(
    parameter MEM_FILE = "memfile_I.dat"  // 命令メモリファイル名
)(
    input clk,
    input reset,
    
    // 各コアからのデバッグ出力（フラット化）
    output [31:0] debug_regs_core0_0,
    output [31:0] debug_regs_core0_1,
    output [31:0] debug_regs_core0_2,
    output [31:0] debug_regs_core0_3,
    output [31:0] debug_regs_core1_0,
    output [31:0] debug_regs_core1_1,
    output [31:0] debug_regs_core1_2,
    output [31:0] debug_regs_core1_3
);

    // コアと調停器間のメモリインタフェース信号
    wire core0_dmem_req, core0_dmem_write;
    wire [31:0] core0_dmem_addr, core0_dmem_write_data, core0_dmem_read_data;
    wire core0_imem_req;
    wire [31:0] core0_imem_addr, core0_imem_read_data;
    
    wire core1_dmem_req, core1_dmem_write;
    wire [31:0] core1_dmem_addr, core1_dmem_write_data, core1_dmem_read_data;
    wire core1_imem_req;
    wire [31:0] core1_imem_addr, core1_imem_read_data;
    
    // 調停器から各コアへのストール信号
    wire core0_stall, core1_stall;

    // シンプルメモリ調停器
    SimpleMemoryArbiter #(
        .MEM_FILE(MEM_FILE)
    ) mem_arbiter (
        .clk(clk),
        .reset(reset),
        
        .core0_dmem_req(core0_dmem_req),
        .core0_dmem_write(core0_dmem_write),
        .core0_dmem_addr(core0_dmem_addr),
        .core0_dmem_write_data(core0_dmem_write_data),
        .core0_dmem_read_data(core0_dmem_read_data),
        
        .core0_imem_req(core0_imem_req),
        .core0_imem_addr(core0_imem_addr),
        .core0_imem_read_data(core0_imem_read_data),
        
        .core1_dmem_req(core1_dmem_req),
        .core1_dmem_write(core1_dmem_write),
        .core1_dmem_addr(core1_dmem_addr),
        .core1_dmem_write_data(core1_dmem_write_data),
        .core1_dmem_read_data(core1_dmem_read_data),
        
        .core1_imem_req(core1_imem_req),
        .core1_imem_addr(core1_imem_addr),
        .core1_imem_read_data(core1_imem_read_data),
        
        .core0_stall(core0_stall),
        .core1_stall(core1_stall)
    );

    // CPUコア0
    SimpleCPUWithMemInterface cpu_core0 (
        .clk(clk),
        .reset(reset),
        .stall(core0_stall),
        
        .dmem_req(core0_dmem_req),
        .dmem_write(core0_dmem_write),
        .dmem_addr(core0_dmem_addr),
        .dmem_write_data(core0_dmem_write_data),
        .dmem_read_data(core0_dmem_read_data),
        
        .imem_req(core0_imem_req),
        .imem_addr(core0_imem_addr),
        .imem_read_data(core0_imem_read_data),
        
        .reg_t0(debug_regs_core0_0),
        .reg_t1(debug_regs_core0_1),
        .reg_t2(debug_regs_core0_2),
        .reg_t3(debug_regs_core0_3)
    );

    // CPUコア1
    SimpleCPUWithMemInterface cpu_core1 (
        .clk(clk),
        .reset(reset),
        .stall(core1_stall),
        
        .dmem_req(core1_dmem_req),
        .dmem_write(core1_dmem_write),
        .dmem_addr(core1_dmem_addr),
        .dmem_write_data(core1_dmem_write_data),
        .dmem_read_data(core1_dmem_read_data),
        
        .imem_req(core1_imem_req),
        .imem_addr(core1_imem_addr),
        .imem_read_data(core1_imem_read_data),
        
        .reg_t0(debug_regs_core1_0),
        .reg_t1(debug_regs_core1_1),
        .reg_t2(debug_regs_core1_2),
        .reg_t3(debug_regs_core1_3)
    );

endmodule