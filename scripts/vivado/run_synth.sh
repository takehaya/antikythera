#!/usr/bin/env bash
#
# Vivado コンテナ内で実行する合成ランナー。
#   単一コア(SingleCycleCPU)とデュアルコア(MultiCoreCPU)を合成し、
#   規模(LUT/FF/BRAM)とタイミング(Fmax)のサマリを並べて出す。
#
#   使い方（コンテナ内のターミナルで）:
#     cd /home/user/antikythera_synth
#     bash run_synth.sh
#
set -e
cd "$(dirname "$0")"

# vivado を PATH に通す（既に通っていれば何もしない）
if ! command -v vivado >/dev/null 2>&1; then
    for s in /home/user/Xilinx/Vivado/*/settings64.sh /opt/Xilinx/Vivado/*/settings64.sh; do
        [ -f "$s" ] && { . "$s"; break; }
    done
fi
echo "vivado: $(command -v vivado || echo 'NOT FOUND — settings64.sh を確認')"

for top in SingleCycleCPU MultiCoreCPU; do
    echo "==================== synth: $top ===================="
    vivado -mode batch -source build_synth.tcl -tclargs "$top" \
           -nojournal -log "vivado_${top}.log" -notrace
done

echo ""
echo "==================== 結果サマリ ===================="
for top in SingleCycleCPU MultiCoreCPU; do
    echo "---- $top : utilization ----"
    grep -E "Slice LUTs|Slice Registers|LUT as Memory|LUT as Logic|Block RAM Tile|RAMB|DSPs|Bonded IOB|F7 Muxes|F8 Muxes" \
         "reports/${top}_utilization.rpt" 2>/dev/null | head -20
    echo "---- $top : timing (WNS=正なら制約達成) ----"
    grep -E "WNS|TNS|Design Timing Summary" -A2 "reports/${top}_timing.rpt" 2>/dev/null | head -8
    echo ""
done
echo "詳細レポート: antikythera_synth/reports/*_utilization.rpt , *_timing.rpt"
echo "（ホスト側の vivado-on-silicon-mac/antikythera_synth/reports/ で開けます）"
