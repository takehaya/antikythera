#!/usr/bin/env bash
set -eo pipefail

root=$(cd -- "$(dirname -- "$0")" && pwd)
mode=${1:-gui}
case "$mode" in
  gui|check) ;;
  *) echo 'Usage: run.sh [gui|check]' >&2; exit 2 ;;
esac
container=${VIVADO_CONTAINER:-vivado-ui-20261011}

if [[ "$mode" == gui ]]; then
  # Use the already-running local demo container; do not touch existing sessions.
  state=$(docker inspect -f '{{.State.Running}}' "$container")
  if [[ "$state" != true ]]; then
    echo "Start the existing Vivado container first: $container" >&2
    exit 1
  fi
  out=$(docker exec "$container" mktemp -d /tmp/teacher-sort.XXXXXX)
  echo "Docker work directory: $out"
  for item in rtl sim case waves.tcl; do
    docker cp "$root/$item" "$container:$out/"
  done
  docker exec -e "DISPLAY=${VIVADO_DISPLAY:-:1}" -w "$out" "$container" bash -c '
    set -eo pipefail
    source /home/user/Xilinx/Vivado/2023.1/settings64.sh
    cp case/*.dat .
    xvlog --sv -i case -i sim rtl/*.v sim/tb_vivado_sort.v
    xelab -debug all -s teacher_sort tb_vivado_sort
    exec xsim teacher_sort -gui -onfinish stop -wdb demo.wdb -tclbatch waves.tcl
  '
else
  command -v iverilog >/dev/null && command -v vvp >/dev/null || {
    echo 'check requires iverilog and vvp on PATH' >&2; exit 1;
  }
  out=$(mktemp -d "${TMPDIR:-/tmp}/teacher-sort.XXXXXX")
  trap 'rm -rf -- "$out"' EXIT
  cd "$out"
  cp "$root"/case/*.dat .
  iverilog -g2012 -s tb_vivado_sort -I "$root/case" -I "$root/sim" \
    -o demo.vvp "$root"/rtl/*.v "$root/sim/tb_vivado_sort.v"
  vvp demo.vvp
  grep -Fx 'PASS: case=original_ten mode=dual n=10 cycles=366 stalls1=77 core1_array_stores=16' result.txt
fi
