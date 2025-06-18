#!/usr/bin/env bash
set -euo pipefail
asm=${1:?need .s file}
out=${2:-memfile_I.dat}

prefix=mips-linux-gnu
as=${prefix}-as
ld=${prefix}-ld
objcopy=${prefix}-objcopy

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

$as -march=mips32 -o "$tmp/prog.o" "$asm"

# note:
# o32 ABIというかSystem V ABIがベースで表現するので
# 16 MB 以上離して配置することが多い。
# memoryの観点からそれは困るので圧縮したいのでリンカーで頑張って潰す
cat > "$tmp/linker.ld" <<'EOF'
ENTRY(_start)
SECTIONS
{
  . = 0x0;
  .text : { *(.text) }
  . = ALIGN(4);
  .data : { *(.data) }
  .bss  : { *(.bss) }
}
EOF

$ld -T "$tmp/linker.ld" -o "$tmp/prog.elf" "$tmp/prog.o"
$objcopy -O binary "$tmp/prog.elf" "$tmp/prog.bin"

hexdump -v -e '4/1 "%02X" "\n"' "$tmp/prog.bin" > "$out"
echo ">> generated $out ($(wc -l < "$out") lines)"
