#!/usr/bin/env bash
#
# antikythera 回帰テストハーネス
#
#   - 全テストベンチを iverilog→vvp で実行（Bashで実行）
#   - 各TBが出力する "RESULT: PASS"（stall TB は "OVERALL TEST RESULT: PASSED"）を集計
#   - 1件でも失敗したら exit 1（CIゲートにできる）
#   - 単一コアと並列の完了サイクルが揃えば SPEEDUP を算出
#
#   使い方:  bash scripts/run_tests.sh
#
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"                      # MEM_FILE は vvp の cwd 相対で解決されるため repo root で実行
SRC="$ROOT/antikythera.srcs/source_1/new"
TB="$ROOT/antikythera.srcs/sim_1/new"
mkdir -p "$ROOT/build"

COMMON="$SRC/alu.v $SRC/alu_control.v $SRC/main_control.v $SRC/register.v $SRC/sign_extender.v $SRC/zero_extender.v $SRC/instaction_memory.v $SRC/data_memory.v"
MULTI="$COMMON $SRC/simple_cpu_with_mem_interface.v $SRC/simple_memory_arbiter.v $SRC/multicore_cpu.v"
SINGLE="$COMMON $SRC/cpu.v"

fail=0
pass=0

run() {  # $1=name  $2="srcs"  $3=tb_file
    local name=$1 srcs=$2 tb=$3
    local out="$ROOT/build/sim_$name" log="$ROOT/build/$name.log"
    if ! iverilog -g2012 -o "$out" "$tb" $srcs 2>"$ROOT/build/$name.compile.log"; then
        echo "[BUILD-FAIL] $name"; cat "$ROOT/build/$name.compile.log"; fail=$((fail+1)); return
    fi
    if perl -e 'alarm 60; exec @ARGV' vvp "$out" >"$log" 2>&1 &&
        grep -qE '^RESULT: PASS([[:space:]]|$)|OVERALL TEST RESULT: PASSED' "$log"; then
        local cyc; cyc=$(grep -oE 'CYCLES=[0-9-]+' "$log" | head -1)
        echo "[PASS] $name ${cyc:+($cyc)}"; pass=$((pass+1))
    else
        echo "[FAIL] $name"; tail -15 "$log"; fail=$((fail+1))
    fi
}

echo "===== antikythera regression ====="

# 0) ゴールデン期待値の裏取り（入力配列 → {0..9}）
if python3 "$ROOT/scripts/gen_golden.py" --check "$ROOT/scripts/testcase/array_input.dat" >/dev/null 2>&1; then
    echo "[PASS] golden (array_input -> {0..9})"; pass=$((pass+1))
else
    echo "[FAIL] golden (gen_golden.py --check)"; fail=$((fail+1))
fi

# 1) 単一コア・バブルソート（性能比較のベースライン）
run single_bubble "$SINGLE" "$TB/tb_single_bubblesort.v"
# 2) デュアルコア CORE_ID 識別
run coreid        "$MULTI"  "$TB/tb_coreid_check.v"
# 3) マルチコア動作デモ（2コアが別領域へ並列に書き込む＝マルチコアが動く実証）
run mc_demo       "$MULTI"  "$TB/tb_multicore_demo.v"
# 4) メモリアービタのストール機構
run stall         "$MULTI"  "$TB/tb_stall_verification.v"

# 5) 並列バブルソート（Step6 で parallel_bubblesort.dat 生成後に自動で有効化）
if [ -f "$ROOT/scripts/testcase/parallel_bubblesort.dat" ]; then
    run par_full "$MULTI" "$TB/tb_parallel_bubblesort.v"
else
    echo "[PENDING] par_full  (scripts/testcase/parallel_bubblesort.dat 未生成 — Step6完了後に有効化)"
fi

# 並列ソートの完成版は独立したデモのRTLとテストベンチで検査する。
if "$ROOT/demos/parallel-sort/run.sh" check >"$ROOT/build/parallel_demo.log" 2>&1; then
    echo "[PASS] parallel_demo"; pass=$((pass+1))
else
    echo "[FAIL] parallel_demo"; tail -15 "$ROOT/build/parallel_demo.log"; fail=$((fail+1))
fi

# スピードアップ（単一 vs 並列の完了サイクルが両方取れたら）
sc=$(grep -oE 'CYCLES=[0-9]+' "$ROOT/build/single_bubble.log" 2>/dev/null | head -1 | cut -d= -f2)
pc=$(grep -oE 'CYCLES=[0-9]+' "$ROOT/build/par_full.log"      2>/dev/null | head -1 | cut -d= -f2)
if [ -n "${sc:-}" ] && [ -n "${pc:-}" ] && [ "${pc:-0}" -gt 0 ] 2>/dev/null; then
    awk -v s="$sc" -v p="$pc" 'BEGIN{printf "SPEEDUP: %.2fx (single=%d parallel=%d)\n", s/p, s, p}'
fi

echo "=================================="
echo "PASS=$pass FAIL=$fail"
if [ "$fail" -eq 0 ]; then echo ">>> REGRESSION PASSED"; exit 0; else echo ">>> REGRESSION FAILED"; exit 1; fi
