#!/usr/bin/env bash
set -euo pipefail
asm=${1:?need .s file}
out=${2:-memfile_I.dat}

# Big-Endian toolchain
prefix=mips-linux-gnu
as=${prefix}-as
ld=${prefix}-ld
objcopy=${prefix}-objcopy

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

$as  -march=mips32 -o "$tmp/prog.o" "$asm"

# ★ oformat を省略（デフォルトで OK）
$ld  -e _start -Ttext=0x0 -o "$tmp/prog.elf" "$tmp/prog.o"

$objcopy -O binary --only-section=.text "$tmp/prog.elf" "$tmp/prog.bin"

hexdump -v -e '4/1 "%02X" "\n"' "$tmp/prog.bin" > "$out"
echo ">> generated $out ($(wc -l < $out) lines)"
