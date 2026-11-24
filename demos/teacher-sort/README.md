# 2コア並列バブルソート：教員説明用デモ

報告書で使った `original_ten / dual` を、既存のDocker版 Vivado XSim 2023.1で手動実行する。入力は `7 1 4 9 3 8 2 6 5 0`。
デモ専用の固定RTL、テストベンチ、入力・期待値、MIPS命令列を収録した。現在の作業ツリーにあるRTLや `antikythera.xpr` は使用・変更しない。

## 起動

リポジトリのルートで次を実行する。

```sh
./demos/teacher-sort/run.sh
```

前提は既に起動している `vivado-ui-20261011`、コンテナ内の Vivado 2023.1、VNCの画面 `:1`。
コンテナ名を変えるなら `VIVADO_CONTAINER`、ディスプレイを変えるなら `VIVADO_DISPLAY` を指定する。
画面共有でこの環境に繋ぐ場合は従来どおり `vnc://127.0.0.1:5901`。
コンテナ内に毎回別の一時ディレクトリを用意する。既存のXSimを終了せず、Dockerの設定やソースも書き換えない。
新しいXSim画面が出たら、最初の `READY:` は波形を開いた合図であり、共有RAM上の `ready` 信号やPASSとは別。

## 手で進める

起動直後はシミュレーションを進めない。XSim下部の **Tcl Console** に以下を**一行ずつ**入力して、説明のたびに止める。
コンソールが隠れていれば **Window → Tcl Console**。既に進めた状態で最初から再演する場合だけ、先に `restart`。

| 手で入れるコマンド | その場で見せること |
| --- | --- |
| `run 1086 ns` | 初期化後、両コアが共有データメモリを要求する。Waveの1075〜1085 ns付近で `req0=req1=1`、`stall1=1`、`pc1=0xd4` のまま。優先されるCore 0は進む。 |
| `run 20 ns` | 1095〜1105 ns付近で競合が解け、`stall1=0`。その後 `pc1` は `0xd4` から `0xd8` に進む。 |
| `teacher_view_sync` | 同期を見る波形に切り替える。ここでは時刻は進まない。 |
| `run 900 ns` | 先に `left_done`、次に `right_done`。両方が揃ってからCore 0が結果をマージする。 |
| `run 2000 ns` | 本ケースは約3768 nsで終了し、Consoleに `INPUT:`、`OUTPUT:`、`PASS:` が出る。 |
| `teacher_view_result` | 共有RAMの `initial_00`〜`initial_09` と `final_00`〜`final_09` を見せる。Waveで終了側にカーソルを置き、`passed=1` と `0 1 2 3 4 5 6 7 8 9` を確認する。 |

`run` は現在時刻からの追加時間。区切りを飛ばして結果だけ確認するなら時刻0から `run 4000 ns` → `teacher_view_result`。
GUIの **Run For** でも同じ相対時間で進められる。
`teacher_view_pc` でPC・競合の波形に戻せる。

期待結果：`cycles=366`、`stalls1=77`、`core1_array_stores=16`（受理された配列ストア数で、交換回数ではない）。
このデモはRTLシミュレーションのみ。合成・実機動作・動作周波数はここでは確認しない。

## GUIを使わず同じケースを確認

```sh
./demos/teacher-sort/run.sh check
```

既存の `iverilog` と `vvp` が必要。ホストの一時ディレクトリで同じRTL・テストベンチ・入力をコンパイルし、期待されるPASS行をチェックする。
Icarusの確認はDocker XSimのGUI動作を代替するものではない。
