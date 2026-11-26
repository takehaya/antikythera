# antikythera

tiny home made cpu project


## 開発・動作確認

Icarus Verilog（`iverilog`、`vvp`）、Python 3、Perlが必要。リポジトリのルートから実行する。

```sh
bash scripts/run_tests.sh
```

単一コアのバブルソート、コアID、共有メモリへのアクセス、ストール、並列ソートを確認する。
実行ログは `build/` に出る。旧並列ソート用テストは入力ファイルがある場合のみ実行する。
完成版の2コアソートを個別に動かす場合は [並列ソートデモ](demos/parallel-sort/README.md) を参照。

個別のシミュレーションは `make sim-stall`、`make sim-multicore`、`make sim-cpu`。
`make asm` はDockerのMIPSツールチェーンを使い、機械語を `build/testcase/` に生成する。

## trivia
[Mechanismós ton Antikythíron (Μηχανισμός των Αντικυθήρων)](https://en.wikipedia.org/wiki/Antikythera_mechanism)
