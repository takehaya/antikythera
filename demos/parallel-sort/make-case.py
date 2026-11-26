#!/usr/bin/env python3
"""Build an independent demo case without editing the checked-in fixture."""

import argparse
from pathlib import Path
import re


FIXTURE = Path(__file__).resolve().parent / "case"
ROM_INPUT = 0x0800
RAM_ARRAY = 0x1100
MAX_COUNT = 64


def uint32(text):
    try:
        value = int(text, 16 if text.lower().startswith("0x") else 10)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"not an integer: {text}") from exc
    if not 0 <= value <= 0xFFFFFFFF:
        raise argparse.ArgumentTypeError(f"outside uint32 range: {text}")
    return value


def hex_words(words):
    return "".join(f"{word:08x}\n" for word in words)


def make_case(values, output):
    n = len(values)
    left, right = n // 2, n - n // 2
    right_start = RAM_ARRAY + 4 * left
    array_end = RAM_ARRAY + 4 * n
    # Patch only ADDIU immediates. Instruction addresses and branch targets stay fixed.
    patches = {
        0x0020: (0x2406000A, n),            # copy input count
        0x0034: (0x24050005, left),         # Core 0 sort count
        0x0064: (0x24041114, right_start),  # Core 1 sort base
        0x0068: (0x24050005, right),        # Core 1 sort count
        0x00F4: (0x24091114, right_start),  # merge left end
        0x00F8: (0x240A1114, right_start),  # merge right start
        0x00FC: (0x240B1128, array_end),    # merge right end
        0x0174: (0x2406000A, n),            # copy merged result back
    }
    words = [int(line, 16) for line in (FIXTURE / "program.dat").read_text().splitlines()]
    start = ROM_INPUT // 4
    if len(words) != 1024:
        raise ValueError("unexpected program.dat size")
    assembly, data_marker, _ = (FIXTURE / "listing.s").read_text().partition(
        "# Fixed read-only input data in the same ROM image."
    )
    if not data_marker:
        raise ValueError("missing input section in listing.s")
    assembly = assembly.replace("count=10; split=5/5", f"count={n}; split={left}/{right}", 1)
    for addr, (old, imm) in patches.items():
        if words[addr // 4] != old:
            raise ValueError(f"unexpected instruction at 0x{addr:04x}; update the patch map")
        new = (old & 0xFFFF0000) | imm
        words[addr // 4] = new
        pattern = rf"(?m)^(\s*addiu[^\n]*, )\d+(\s+# {addr:04x}: ){old:08x}$"
        assembly, matches = re.subn(pattern, lambda m: f"{m[1]}{imm}{m[2]}{new:08x}", assembly)
        if matches != 1:
            raise ValueError(f"listing.s does not match program.dat at 0x{addr:04x}")

    pad = [0] * (MAX_COUNT - n)
    words[start:start + MAX_COUNT] = values + pad
    right_unsorted = int(values[left:] != sorted(values[left:]))
    metadata = f"{n} 132 {right_unsorted} custom\n"
    listing = assembly + f"# Read-only input data in ROM.\n.org 0x{ROM_INPUT:04x}\ninput_values:\n"
    listing += "".join(f"    .word 0x{v:08x}                       # {ROM_INPUT + 4*i:04x}\n"
                       for i, v in enumerate(values))

    # Refuse an existing destination so the original fixture cannot be overwritten.
    output.mkdir()
    for name, contents in {
        "program.dat": hex_words(words),
        "input.dat": hex_words(values + pad),
        "expected.dat": hex_words(sorted(values) + pad),
        "case-meta.dat": metadata,
        "listing.s": listing,
    }.items():
        (output / name).write_text(contents)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path, help="new directory for the case")
    parser.add_argument("values", nargs="+", type=uint32, metavar="VALUE")
    args = parser.parse_args()
    if not 1 <= len(args.values) <= MAX_COUNT:
        parser.error(f"expected 1 to {MAX_COUNT} input values")
    try:
        make_case(args.values, args.output)
    except (OSError, ValueError) as exc:
        parser.exit(1, f"{parser.prog}: {exc}\n")


if __name__ == "__main__":
    main()
