#!/usr/bin/env bash
set -eo pipefail

root=$(cd -- "$(dirname -- "$0")" && pwd)
mode=${1:-gui}
container=${VIVADO_CONTAINER:-vivado-ui-20261011}
target=
if [[ "$mode" == swap ]]; then
  target=${2:-}
  if [[ ! "$target" =~ ^/tmp/parallel-sort\.[[:alnum:]]{6}$ ]]; then
    echo 'Usage: run.sh swap /tmp/parallel-sort.XXXXXX [-- VALUE ...]' >&2
    exit 2
  fi
  shift
fi

case "$mode" in
  gui|check|swap) ;;
  *) echo 'Usage: run.sh [gui|check] [-- VALUE ...]' >&2; exit 2 ;;
esac
if [[ $# -gt 0 ]]; then shift; fi
case_dir="$root/case"
custom=0
# Custom cases live in a temporary directory; the reference fixture remains unchanged.
if [[ $# -gt 0 ]]; then
  if [[ "$1" != -- || $# -lt 2 ]]; then
    echo 'Usage: run.sh [gui|check] [-- VALUE ...]' >&2
    exit 2
  fi
  shift
  custom=1
  host_case=$(mktemp -d "${TMPDIR:-/tmp}/parallel-sort-case.XXXXXX")
  trap 'rm -rf -- "$host_case"' EXIT
  case_dir="$host_case/case"
  python3 "$root/make-case.py" --output "$case_dir" "$@"
fi

if [[ "$mode" == swap ]]; then
  # Prepare a whole case before switching the symlink. Do not change another session.
  slot=$(docker exec "$container" bash -ec '
    test -f "$1/.case-reload"
    mktemp -d "$1/case.XXXXXX"
  ' _ "$target")
  docker cp "$case_dir/." "$container:$slot/"
  docker exec -w "$target" "$container" bash -ec '
    test -s "$1/case-meta.dat"
    ln -s "$1" "$1.link"
    mv -Tf "$1.link" active-case
  ' _ "$slot"
  echo 'Case ready. Enter restart in the same XSim Tcl Console, then run -all.'
elif [[ "$mode" == gui ]]; then
  # Use the already-running local demo container; do not touch existing sessions.
  state=$(docker inspect -f '{{.State.Running}}' "$container")
  if [[ "$state" != true ]]; then
    echo "Start the existing Vivado container first: $container" >&2
    exit 1
  fi
  # デモ用のRTL・入力を専用ディレクトリにコピーし、既存プロジェクトと分離する。
  out=$(docker exec "$container" mktemp -d /tmp/parallel-sort.XXXXXX)
  echo "Docker work directory: $out"
  for item in rtl sim waves.tcl; do
    docker cp "$root/$item" "$container:$out/"
  done
  docker cp "$case_dir" "$container:$out/case"
  docker exec -e "DISPLAY=${VIVADO_DISPLAY:-:1}" -w "$out" "$container" bash -c '
    set -eo pipefail
    source /home/user/Xilinx/Vivado/2023.1/settings64.sh
    ln -s case active-case
    touch .case-reload
    # RTLとテストベンチをコンパイルし、XSimが読み込むスナップショットを作る。
    xvlog --sv -i sim rtl/*.v sim/tb_vivado_sort.v
    xelab -debug all -s parallel_sort tb_vivado_sort
    exec xsim parallel_sort -gui -onfinish stop -wdb demo.wdb -tclbatch waves.tcl
  '
else
  command -v iverilog >/dev/null && command -v vvp >/dev/null || {
    echo 'check requires iverilog and vvp on PATH' >&2; exit 1;
  }
  out=$(mktemp -d "${TMPDIR:-/tmp}/parallel-sort.XXXXXX")
  trap 'rm -rf -- "$out"; if [[ -n "${host_case:-}" ]]; then rm -rf -- "$host_case"; fi' EXIT
  cd "$out"
  ln -s "$case_dir" active-case
  # GUIを使わず、同じRTLと期待値で結果を照合する。
  iverilog -g2012 -s tb_vivado_sort -I "$root/sim" \
    -o demo.vvp "$root"/rtl/*.v "$root/sim/tb_vivado_sort.v"
  vvp demo.vvp
  if [[ "$custom" == 1 ]]; then
    grep -E '^PASS: case=custom mode=dual n=[0-9]+ cycles=[0-9]+' result.txt
  else
    grep -Fx 'PASS: case=original_ten mode=dual n=10 cycles=366 stalls1=77 core1_array_stores=16' result.txt
  fi
fi
