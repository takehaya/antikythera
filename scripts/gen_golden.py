#!/usr/bin/env python3
"""入力配列のゴールデン(期待値)を生成・検証する外部リファレンス。

並列バブルソート検証の「期待値そのものが間違っている」最悪ケースを排除するため、
テストベンチがハードコードする期待値を Python の sorted() で独立に裏取りする。

使い方:
  python3 scripts/gen_golden.py scripts/testcase/array_input.dat
      入力配列とソート済みゴールデンを表示する。
  python3 scripts/gen_golden.py --check scripts/testcase/array_input.dat
      ソート結果が {0..9} になることを assert（回帰スクリプトから呼ぶ）。失敗で非ゼロ終了。
"""
import sys


def read_words(path):
    """1行1ワード(16進)の .dat を読む。'//' 以降と空行は無視。"""
    out = []
    with open(path) as f:
        for ln in f:
            ln = ln.split('//')[0].strip()
            if ln:
                out.append(int(ln, 16))
    return out


def main(argv):
    args = [a for a in argv[1:] if not a.startswith('--')]
    check = '--check' in argv
    if not args:
        print('usage: gen_golden.py [--check] <array_input.dat>', file=sys.stderr)
        return 2
    inp = read_words(args[-1])
    golden = sorted(inp)
    print('INPUT  =', inp)
    print('GOLDEN =', golden)
    if check:
        expected = list(range(len(inp)))
        if golden != expected:
            print(f'GOLDEN MISMATCH: expected {expected} got {golden}', file=sys.stderr)
            return 1
        print('GOLDEN OK')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
