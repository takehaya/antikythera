#!/usr/bin/env python3
"""VCD をクロック立ち上がりでサンプリングし、指定信号の per-cycle タイムチャートを
ASCII で表示する（gtkwave 無し環境での波形プレビュー / スライド貼り付け用）。

使い方:
  python3 scripts/vcd_ascii.py build/stall_wave.vcd \
      --clk uut.clk --from 8 --to 22 \
      --sig uut.core0_dmem_req --sig uut.core1_dmem_req --sig uut.core1_stall \
      --bus uut.cpu_core0.PC --bus uut.cpu_core1.PC

  信号名は VCD 内フルパスの「末尾一致」で照合する（例: uut.core1_stall）。
"""
import argparse, sys


def parse_vcd(path):
    """VCD を読み、{full_path: id} と、時刻ごとの値変化リストを返す。"""
    name2id = {}
    scope = []
    changes = []  # (time, id, value)
    cur_t = 0
    with open(path) as f:
        toks = f.read().split()
    i = 0
    while i < len(toks):
        t = toks[i]
        if t == '$scope':
            scope.append(toks[i + 2]); i += 4; continue
        if t == '$upscope':
            if scope: scope.pop()
            i += 2; continue
        if t == '$var':
            # $var <type> <size> <id> <name> [range] $end
            vid = toks[i + 3]; name = toks[i + 4]
            full = '.'.join(scope + [name])
            name2id[full] = vid
            j = i + 5
            while toks[j] != '$end':
                j += 1
            i = j + 1; continue
        if t.startswith('#'):
            cur_t = int(t[1:]); i += 1; continue
        if t in ('$dumpvars', '$end', '$dumpall', '$dumpon', '$dumpoff', '$comment'):
            i += 1; continue
        # 値変化: スカラ "0id"/"1id"/"xid" or ベクタ "b1010 id"
        if t[0] in '01xzXZ' and len(t) > 1:
            changes.append((cur_t, t[1:], t[0])); i += 1; continue
        if t[0] == 'b':
            val = t[1:]; vid = toks[i + 1]
            changes.append((cur_t, vid, val)); i += 2; continue
        i += 1
    return name2id, changes


def resolve(name2id, suffix):
    hits = [full for full in name2id if full == suffix or full.endswith('.' + suffix)]
    if not hits:
        return None
    # 最短一致（最も具体的）
    return name2id[min(hits, key=len)]


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument('vcd')
    ap.add_argument('--clk', required=True)
    ap.add_argument('--sig', action='append', default=[])   # 1bit
    ap.add_argument('--bus', action='append', default=[])   # 多bit（hex表示）
    ap.add_argument('--from', dest='c0', type=int, default=0)
    ap.add_argument('--to', dest='c1', type=int, default=40)
    a = ap.parse_args(argv[1:])

    name2id, changes = parse_vcd(a.vcd)
    wanted = [a.clk] + a.sig + a.bus
    ids = {}
    for w in wanted:
        vid = resolve(name2id, w)
        if vid is None:
            print(f"WARN: signal not found: {w}", file=sys.stderr)
        ids[w] = vid
    clk_id = ids[a.clk]

    # 時刻順に値を再生し、clk の 0->1 立ち上がりで各信号をサンプル
    cur = {vid: 'x' for vid in name2id.values()}
    samples = []  # 各cycleの {name: value}
    prev_clk = '0'
    # changes は時刻順だが同一時刻に複数。時刻でまとめて適用してからエッジ判定
    from itertools import groupby
    for t, grp in groupby(changes, key=lambda c: c[0]):
        for _, vid, val in grp:
            cur[vid] = val
        c = cur.get(clk_id, '0')
        if prev_clk == '0' and c == '1':
            row = {}
            for w in a.sig:
                row[w] = cur.get(ids[w], '?')
            for w in a.bus:
                v = cur.get(ids[w], 'x')
                try:
                    row[w] = '0x%x' % int(v, 2)
                except ValueError:
                    row[w] = v
            samples.append(row)
        prev_clk = c

    lo, hi = a.c0, min(a.c1, len(samples) - 1)
    cycles = list(range(lo, hi + 1))
    print(f"# {a.vcd}  cycles {lo}..{hi}（clk立ち上がりサンプル）\n")
    hdr = "cycle".ljust(22) + "".join(f"{c:>4}" for c in cycles)
    print(hdr)
    print("-" * len(hdr))
    # 1bit信号: 0=▁ 1=▇ で見やすく
    for w in a.sig:
        cells = []
        for c in cycles:
            v = samples[c].get(w, '?') if c < len(samples) else '?'
            cells.append({'0': '  ▁', '1': '  ▇'}.get(v, f'  {v}'))
        print(w.ljust(22) + "".join(f"{x:>4}" for x in cells))
    # bus: 値をそのまま
    for w in a.bus:
        cells = [samples[c].get(w, '?') if c < len(samples) else '?' for c in cycles]
        print(w.ljust(22) + "".join(f"{x:>6}" for x in cells))


if __name__ == '__main__':
    main(sys.argv)
