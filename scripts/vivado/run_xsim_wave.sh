#!/usr/bin/env bash
#
# Core1 ストールの波形を Vivado xsim で生成/表示する。
#
#   使い方（コンテナ内 /home/user/antikythera_synth）:
#     bash run_xsim_wave.sh        # ヘッドレス: 波形DB(WDB)を生成（docker exec から可）
#     bash run_xsim_wave.sh gui    # VNCデスクトップ上: GUIで波形ビューアを開く
#
set -e
cd "$(dirname "$0")"

if ! command -v xsim >/dev/null 2>&1; then
    for s in /home/user/Xilinx/Vivado/*/settings64.sh /opt/Xilinx/Vivado/*/settings64.sh; do
        [ -f "$s" ] && { . "$s"; break; }
    done
fi
echo "xsim: $(command -v xsim || echo 'NOT FOUND')"

TB=tb_stall_wave
rm -rf xsim.dir .Xil *.jou *.log *.pb *.wdb xelab.* xvlog.* 2>/dev/null || true

RTL="rtl/alu.v rtl/alu_control.v rtl/main_control.v rtl/register.v rtl/sign_extender.v rtl/zero_extender.v rtl/instaction_memory.v rtl/data_memory.v rtl/simple_cpu_with_mem_interface.v rtl/simple_memory_arbiter.v rtl/multicore_cpu.v"
xvlog $RTL
xvlog --sv "sim/${TB}.v"
# 波形にアクセスできるよう -debug typical でエラボレート
xelab "$TB" -s "${TB}_snap" -debug typical

if [ "${1:-}" = "gui" ]; then
    echo ">> GUIで波形を表示（VNCデスクトップ上で実行してください）"
    xsim "${TB}_snap" -gui -tclbatch wave_stall.tcl
else
    echo ">> ヘッドレスで波形DB(WDB)を生成"
    xsim "${TB}_snap" -tclbatch wave_stall_log.tcl
    echo ""
    echo ">> 生成された WDB:"; ls -1 *.wdb 2>/dev/null || echo "  (WDB名は下のlsで確認)"
    echo ">> VNC内のVivado GUIで波形を見るには:"
    echo "     cd /home/user/antikythera_synth && bash run_xsim_wave.sh gui"
fi
