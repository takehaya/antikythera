# asm
全くもって毎回毎回アセンブラを手で頑張ってhexにするのはもう無理ではという気持ちになったので、ここは文明の力ことコンパイラさんの力を借りてなんとかできる様にしました。ざっくりやり方を書きます。

まずはパッケージを持ってきます
```shell
sudo apt-get update
sudo apt-get install gcc-mips-linux-gnu binutils-mips-linux-gnu binutils-mipsel-linux-gnu
```

次に以下のようなasmファイルを用意します。
- 順序最適化禁止を入れないと、期待してる順番で出てこないので強制します
- _startをmain関数としてみてます。
```asm
.globl  _start
.set    noreorder
_start:
    <任意のアセンブラ>

spin:
    beq $zero, $zero, spin
    nop
```

これを利用して適当なアセンブラを書いて実行します
```shell
./scripts/mips2hex.sh ./scripts/sample01.s
```

そうすると、以下の様なファイル名でこんな感じの便利なアセンブラを吐き出してくれます。多分概ねあってそうです。
（手でメモをしたのがsample01.sについてるので、それと比較してみてください）
```
$ cat memfile_I.dat 
20080005
2009000A
0C000004
01405820
01095020
03E00008
00000000
00000000
```

## アセンブラの書き方メモ
- https://brain.cc.kogakuin.ac.jp/~kanamaru/lecture/MP/final/part04/node6.html
- https://www.swlab.cs.okayama-u.ac.jp/~nom/lect/p3/what-is-calling-convention.html

- b命令
```s
# b label
beq   $zero, $zero, ラベル 
nop
```

アセンブラの擬似命令で、ISAにはない。ジャンプ（厳密には条件付きjumpに0を入れて常に飛ばす感じ）です。j命令でもできる。
