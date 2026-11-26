# Vivado xsim GUI 用: Core1ストール可視化の波形セットアップ
#   run_xsim_wave.sh gui から呼ばれる。主要信号を Wave に追加して最後まで実行する。
#
#   読み方:
#     core0_dmem_req と core1_dmem_req が同時に 1 になった瞬間 → core1_stall が 1。
#     その間 cpu_core1/PC は 0x34（Core1のsw命令）で停止し、cpu_core0/PC だけ進む。
#     ストール解除後に Core1 が再開する。これが約9サイクル周期で繰り返す。

add_wave -radix bin /tb_stall_wave/uut/clk
add_wave -radix bin /tb_stall_wave/uut/reset
add_wave -radix bin /tb_stall_wave/uut/core0_dmem_req
add_wave -radix bin /tb_stall_wave/uut/core1_dmem_req
add_wave -radix bin /tb_stall_wave/uut/core1_stall
add_wave -radix hex /tb_stall_wave/uut/cpu_core0/PC
add_wave -radix hex /tb_stall_wave/uut/cpu_core1/PC

run all
