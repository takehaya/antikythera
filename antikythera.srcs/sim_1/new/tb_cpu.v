`timescale 1ns/1ps
module tb_SingleCycleCPU();

reg clk = 0;
reg reset = 1;
wire [31:0] t0, t1, t2, t3;

// デバッグ用ループ変数
integer i;

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

    // 1000nsほど動かす
    #1000;
    $stop;
end

// initial begin
// //     $monitor("Time=%0t | PC=%h | Instruction=%h | t0=%h t1=%h t2=%h t3=%h",
// //               $time, uut.PC, uut.Instruction, t0, t1, t2, t3);

// $monitor(
//     "Time=%0t | PC=%h | Instruction=%h | rs=%2d rt=%2d | RegWrite=%b WriteReg=%2d WriteData=%h | ALUSrc=%b | regData1=%h regData2=%h ImmVal=%h ALUInput2=%h | t0=%h t1=%h t2=%h t3=%h",
//     $time, uut.PC, uut.Instruction,
//     uut.Instruction[25:21], uut.Instruction[20:16],
//     uut.RegWrite, uut.WriteReg, uut.WriteData,
//     uut.ALUSrc, uut.regData1, uut.regData2, uut.ImmVal, uut.ALUInput2,
//     t0, t1, t2, t3
// );
// $monitor($time,
//   " PC=%h Op=%h Zero=%b | Branch=%b BranchNot=%b -> take=%b",
//   uut.PC, uut.Instruction[31:26],
//   uut.ZeroFlag, uut.Branch, uut.BranchNot, uut.takeBranch);

//     // show memory dump
//     for (i = 0; i < 10; i = i + 1) begin
//         $display("mem[%0d] = %h", i, uut.dmem.get_mem_val(8'h2C + i));
//     end

// end

endmodule
