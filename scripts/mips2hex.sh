#!/usr/bin/env bash
set -euo pipefail
asm=${1:?need .s file}
out=${2:-memfile_I.dat}

# .s ファイルを絶対パスに変換
asm=$(cd "$(dirname "$asm")" && pwd)/$(basename "$asm")
out_dir=$(cd "$(dirname "$out")" && pwd)
out_name=$(basename "$out")

DOCKER_IMAGE="antikythera-mips-toolchain"

# イメージがなければビルド
if ! docker image inspect "$DOCKER_IMAGE" &>/dev/null; then
    echo ">> building Docker image (initial setup, takes ~1 min)..."
    docker build -t "$DOCKER_IMAGE" -f - "$(dirname "$0")" <<'DOCKERFILE'
FROM ubuntu:22.04
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      binutils-mips-linux-gnu bsdmainutils && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /work
DOCKERFILE
fi

# アセンブル → リンク → バイナリ変換 → hex化
docker run --rm \
    -v "$asm:/work/input.s:ro" \
    -v "$out_dir:/work/out" \
    -e "OUT_NAME=$out_name" \
    "$DOCKER_IMAGE" bash -c '
set -euo pipefail

prefix=mips-linux-gnu
tmp=$(mktemp -d)
trap "rm -rf $tmp" EXIT

${prefix}-as -march=mips32 -o "$tmp/prog.o" /work/input.s

# o32 ABI のデフォルト配置は 16MB+ 離れるので、リンカスクリプトで 0x0 始まりに潰す
cat > "$tmp/linker.ld" <<LDEOF
ENTRY(_start)
SECTIONS
{
  . = 0x0;
  .text : { *(.text) }
  . = ALIGN(4);
  .data : { *(.data) }
  .bss  : { *(.bss) }
}
LDEOF

${prefix}-ld -T "$tmp/linker.ld" -o "$tmp/prog.elf" "$tmp/prog.o"
${prefix}-objcopy -O binary "$tmp/prog.elf" "$tmp/prog.bin"

hexdump -v -e '"'"'4/1 "%02X" "\n"'"'"' "$tmp/prog.bin" > "/work/out/$OUT_NAME"
echo ">> generated $OUT_NAME ($(wc -l < "/work/out/$OUT_NAME") lines)"
'
