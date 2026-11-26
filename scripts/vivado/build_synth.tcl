# antikythera 合成バッチスクリプト（Vivado 非プロジェクトフロー）
#
#   ロジックの規模(LUT/FF/BRAM)と動作速度(Fmax)だけを見るための最小フロー。
#   実装(配置配線)やビットストリームは作らない。ボード不要。
#
#   使い方（コンテナ内）:
#     vivado -mode batch -source build_synth.tcl -tclargs SingleCycleCPU
#     vivado -mode batch -source build_synth.tcl -tclargs MultiCoreCPU
#
#   ※ run_synth.sh が両方をまとめて実行する。

set top [lindex $argv 0]
if {$top eq ""} { set top SingleCycleCPU }

set part         "xc7z010clg400-1"   ;# Zynq-7010 (Digilent Zybo)
set clk_period_ns 10.0               ;# 仮の100MHz目標。Fmax = 1000/(period_ns - WNS_ns)

file mkdir reports

# --- 合成対象ソース（旧統合メモリ memory.v とテストベンチは含めない） ---
set common {
    rtl/alu.v
    rtl/alu_control.v
    rtl/main_control.v
    rtl/register.v
    rtl/sign_extender.v
    rtl/zero_extender.v
    rtl/instaction_memory.v
    rtl/data_memory.v
}
if {$top eq "MultiCoreCPU"} {
    set files [concat $common {
        rtl/simple_cpu_with_mem_interface.v
        rtl/simple_memory_arbiter.v
        rtl/multicore_cpu.v
    }]
} else {
    set files [concat $common {rtl/cpu.v}]
}

puts "######## SYNTH $top on $part ########"
read_verilog $files

# out_of_context: I/Oバッファを挿さない。
#   デバッグ用に32bit×多数の出力ポートがあり、そのままだとピン数超過でエラーになる。
#   ロジックの規模・速度を見るのが目的なので I/O は外す。
synth_design -top $top -part $part -mode out_of_context

# Fmax 見積り用の仮クロック制約
if {[llength [get_ports -quiet clk]] > 0} {
    create_clock -name clk -period $clk_period_ns [get_ports clk]
}

report_utilization    -file reports/${top}_utilization.rpt
report_timing_summary -file reports/${top}_timing.rpt -max_paths 10

puts "\n======== $top : Utilization ========"
report_utilization
puts "\n======== $top : Timing summary ========"
report_timing_summary -max_paths 1

puts "\n######## DONE $top  (詳細は reports/${top}_*.rpt) ########"
