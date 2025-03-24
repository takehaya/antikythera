`timescale 1ns/1ps
module tb_SingleCycleCPU();

reg clk = 0;
reg reset = 1;
wire [31:0] t0, t1, t2, t3;

SingleCycleCPU uut (
    .clk(clk),
    .reset(reset),
    .reg_t0(t0),
    .reg_t1(t1),
    .reg_t2(t2),
    .reg_t3(t3)
);

// クロック生成 (10ns周期)
always #5 clk = ~clk;

initial begin
    #21;       // リセットを少し維持
    reset = 0; // CPUスタート

    // 500nsほど動かす
    #500;

    $stop;
    //$finish;
end

initial begin
    $monitor("Time=%0t | PC=%h | Instruction=%h | t0=%h t1=%h t2=%h t3=%h",
              $time, uut.PC, uut.Instruction, t0, t1, t2, t3);
end

endmodule
