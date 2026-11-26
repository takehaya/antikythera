# 2コア並列バブルソート：デモ

10要素の2コア並列ソート（`original_ten / dual`）を、Docker版 Vivado XSim 2023.1で実行し、共有メモリの競合、コア間の同期、整列結果を波形で確認する。入力は `7 1 4 9 3 8 2 6 5 0`。
デモ専用の固定RTL、テストベンチ、入力・期待値、MIPS命令列を収録した。現在の作業ツリーにあるRTLや `antikythera.xpr` は使用・変更しない。

## CPUが実行するプログラム

[`case/listing.s`](case/listing.s) は、このCPU向けの32ビットMIPS風アセンブリの命令一覧。
各命令の右にアドレスと機械語を併記している。XSimが命令ROMに読み込むのは、対応する
`case/program.dat` であり、起動時に `listing.s` をアセンブルするわけではない。
同じ命令列を読む両コアが、冒頭のコアID読み出しで役割を分ける。
`0x00d4` と `0x00d8` の2本の `sw` が、波形で追う隣接要素の交換に対応する。

## 起動

リポジトリのルートで次を実行する。

```sh
./demos/parallel-sort/run.sh
```

前提は既に起動している `vivado-ui-20261011`、コンテナ内の Vivado 2023.1、VNCの画面 `:1`。
コンテナ名を変えるなら `VIVADO_CONTAINER`、ディスプレイを変えるなら `VIVADO_DISPLAY` を指定する。
画面共有でこの環境に繋ぐ場合は従来どおり `vnc://127.0.0.1:5901`。
コンテナ内に毎回別の一時ディレクトリを用意する。既存のXSimを終了せず、Dockerの設定やソースも書き換えない。
新しいXSim画面が出たら、最初の `READY:` は波形を開いた合図であり、共有RAM上の `ready` 信号やPASSとは別。

## シミュレーションを進めて波形を確認する

起動直後はシミュレーションを進めない。XSim下部の **Tcl Console** に以下を**一行ずつ**入力し、各ステップの信号を確認する。
コンソールが隠れていれば **Window → Tcl Console**。シミュレーションを最初からやり直す場合は、先に `restart`。

| Tclコマンド | 確認する動作 |
| --- | --- |
| `run 1086 ns` | 初期化後、両コアが共有データメモリを要求する。Waveの1075〜1085 ns付近で `req0=req1=1`、`stall1=1`、`pc1=0xd4` のまま。優先されるCore 0は進む。 |
| `run 20 ns` | 1095〜1105 ns付近で競合が解け、`stall1=0`。その後 `pc1` は `0xd4` から `0xd8` に進む。 |
| `demo_view_sync` | 同期を見る波形に切り替える。ここでは時刻は進まない。 |
| `run 700 ns` | 1806 nsで停止。前半だけ整列済み（`left_done=1`、`right_done=0`）。Core 0は後半の完了を待つ。 |
| `run 200 ns` | 2006 nsで停止。両方が整列済み（`left_done=1`、`right_done=1`）。マージと書き戻しが済むまでは `complete=0`。 |
| `run 2000 ns` | 本ケースは約3768 nsで終了し、Consoleに `INPUT:`、`OUTPUT:`、`PASS:` が出る。 |
| `demo_view_result` | 共有RAMの `initial_00`〜`initial_09` と `final_00`〜`final_09` を表示する。Waveで終了側にカーソルを置き、`passed=1` と `0 1 2 3 4 5 6 7 8 9` を確認する。 |

`run` は現在時刻からの追加時間。区切りを飛ばして結果だけ確認するなら時刻0から `run 4000 ns` → `demo_view_result`。
GUIの **Run For** でも同じ相対時間で進められる。
`demo_view_pc` でPC・競合の波形に戻せる。

期待結果：`cycles=366`、`stalls1=77`、`core1_array_stores=16`（受理された配列ストア数で、交換回数ではない）。
このデモはRTLシミュレーションのみ。合成・実機動作・動作周波数はここでは確認しない。

## GUIを使わず同じケースを確認

```sh
./demos/parallel-sort/run.sh check
```

既存の `iverilog` と `vvp` が必要。ホストの一時ディレクトリで同じRTL・テストベンチ・入力をコンパイルし、期待されるPASS行をチェックする。
Icarusの確認はDocker XSimのGUI動作を代替するものではない。

## 入力を変えて実行する

`gui --` または `check --` の後に、1〜64個の符号なし32ビット整数を指定する。
10進数と `0x` 付きの16進数が使える。奇数個の場合、後半のコアが1個多く担当する。

```sh
./demos/parallel-sort/run.sh gui -- 12 3 7 4 1 20 0 6 2 8 5 11
./demos/parallel-sort/run.sh check -- 12 3 7 4 1 20 0 6 2 8 5 11
```

元の `case/` は変更しない。入力・命令ROM・期待値・分割設定を一時ディレクトリに生成し、
テストベンチで全要素を照合する。入力を変えると波形の時刻も変わるので、
XSimでは `run -all` で最後まで進め、Consoleの `INPUT:`・`OUTPUT:`・`PASS:` を確認する。
`demo_view_result` の個別信号は先頭10要素分で、Consoleには全要素が出る。

生成した機械語やアセンブリを後から確認したい場合は、新しい出力先を指定して
ケースを生成しておく。

```sh
python3 demos/parallel-sort/make-case.py --output /tmp/my-sort-case 12 3 7 4 1 20 0 6 2 8 5 11
```

## XSimを開いたまま入力を差し替える

この版の `run.sh gui` で一度起動し、Macのターミナルに表示される
`Docker work directory: /tmp/parallel-sort.XXXXXX` を控える。
実行を止めた状態で、Macの別ターミナルから、そのディレクトリに新しいケースを配置する。

```sh
./demos/parallel-sort/run.sh swap /tmp/parallel-sort.XXXXXX -- 12 3 7 4 1 20 0 6 2 8 5 11
```

`XXXXXX` は実際に表示されたものに置き換える。同じXSimの **Tcl Console** に
`restart`、`run -all` を順に入力する。命令ROM・入力・期待値と件数は再起動時に
ファイルから読み直すため、XSimウィンドウを開き直したり、RTLを再コンパイルしたりする必要はない。
元の10要素に戻すときは同じ `swap` コマンドから `--` 以降を省略し、もう一度 `restart` する。
この版より前に開いたウィンドウでは、最初の一度だけ開き直す必要がある。
