#!/usr/bin/env bash
#
# antikythera の合成用RTLとスクリプトを、Vivadoコンテナから見える
# vivado-on-silicon-mac/antikythera_synth/ にコピー（デプロイ）する。
#
#   - コンテナは vivado-on-silicon-mac フォルダを /home/user にバインドマウントしている。
#     そのためソースは必ずこのフォルダ配下に置く必要がある（マウント外はコンテナから見えない）。
#   - バインドマウントはライブなので、ホストでコピーすれば実行中コンテナにも即反映される。
#   - RTLを更新したら再度このスクリプトを実行して同期する（コピーなので古くなる点に注意）。
#
#   使い方（ホスト=Mac側で）:
#     bash scripts/vivado/sync_to_container.sh
#   その後コンテナ内で:
#     cd /home/user/antikythera_synth && bash run_synth.sh
#
set -e

ROOT=$(cd "$(dirname "$0")/../.." && pwd)               # antikythera repo root
VIVADO_DIR="${VIVADO_DIR:-$HOME/private/vivado-on-silicon-mac}"
DST="$VIVADO_DIR/antikythera_synth"
SRC="$ROOT/antikythera.srcs/source_1/new"

if [ ! -d "$VIVADO_DIR" ]; then
    echo "ERROR: vivado-on-silicon-mac が見つからない: $VIVADO_DIR" >&2
    echo "       環境変数 VIVADO_DIR で場所を指定できます。" >&2
    exit 1
fi

mkdir -p "$DST/rtl" "$DST/reports"

# 合成対象RTL（旧統合メモリ memory.v とテストベンチは含めない）
RTL_FILES="alu.v alu_control.v main_control.v register.v sign_extender.v zero_extender.v \
           instaction_memory.v data_memory.v cpu.v \
           simple_cpu_with_mem_interface.v simple_memory_arbiter.v multicore_cpu.v"
for f in $RTL_FILES; do
    cp "$SRC/$f" "$DST/rtl/$f"
done

# 命令メモリ初期化ファイル（$readmemh 用。規模見積りに中身は無関係だが、無いと警告が出る）
cp "$ROOT/scripts/testcase/single_bubblesort.dat" "$DST/memfile_I.dat"

# 合成スクリプト
cp "$ROOT/scripts/vivado/build_synth.tcl" "$DST/build_synth.tcl"
cp "$ROOT/scripts/vivado/run_synth.sh"    "$DST/run_synth.sh"

# --- Vivado xsim（behavioralシミュレーション）用の資産 ---
mkdir -p "$DST/sim" "$DST/scripts/testcase"
# シミュレーション対象のテストベンチ
for tb in tb_multicore_demo tb_stall_wave; do
    cp "$ROOT/antikythera.srcs/sim_1/new/$tb.v" "$DST/sim/$tb.v"
done
# TB が $readmemh する .dat（MEM_FILE は実行cwd相対なので antikythera_synth/scripts/testcase/ に置く）
for dat in multicore_demo stall_stress; do
    cp "$ROOT/scripts/testcase/$dat.dat" "$DST/scripts/testcase/$dat.dat"
done
# xsim ランナー & 波形TCL
cp "$ROOT/scripts/vivado/run_xsim.sh"        "$DST/run_xsim.sh"
cp "$ROOT/scripts/vivado/run_xsim_wave.sh"   "$DST/run_xsim_wave.sh"
cp "$ROOT/scripts/vivado/wave_stall.tcl"     "$DST/wave_stall.tcl"
cp "$ROOT/scripts/vivado/wave_stall_log.tcl" "$DST/wave_stall_log.tcl"

echo "synced -> $DST"
ls -la "$DST" "$DST/rtl"
