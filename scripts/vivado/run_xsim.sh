#!/usr/bin/env bash
#
# Vivado xsim（behavioralシミュレータ）でテストベンチを実行する。
#   iverilog と同じ自己検証TBを Vivado のツールで走らせ、同じ RESULT: PASS が出ることを示す。
#
#   使い方（コンテナ内）:
#     cd /home/user/antikythera_synth
#     bash run_xsim.sh [TB名]      # 既定: tb_multicore_demo
#
set -e
cd "$(dirname "$0")"

# Vivado(xsim) を PATH に
if ! command -v xsim >/dev/null 2>&1; then
    for s in /home/user/Xilinx/Vivado/*/settings64.sh /opt/Xilinx/Vivado/*/settings64.sh; do
        [ -f "$s" ] && { . "$s"; break; }
    done
fi
echo "xsim: $(command -v xsim || echo 'NOT FOUND')"

TB="${1:-tb_multicore_demo}"
echo "==================== Vivado xsim: $TB ===================="

# 前回の生成物を掃除
rm -rf xsim.dir .Xil *.jou *.log *.pb xelab.* xvlog.* 2>/dev/null || true

# マルチコアRTL + TB をコンパイル（RTLはVerilog、TBはSystemVerilog: $fatal等）
RTL="rtl/alu.v rtl/alu_control.v rtl/main_control.v rtl/register.v rtl/sign_extender.v rtl/zero_extender.v rtl/instaction_memory.v rtl/data_memory.v rtl/simple_cpu_with_mem_interface.v rtl/simple_memory_arbiter.v rtl/multicore_cpu.v"
xvlog $RTL
xvlog --sv "sim/${TB}.v"

# エラボレート → シミュレーション（$finish まで走る）
xelab "$TB" -s "${TB}_snap"
xsim "${TB}_snap" -runall
