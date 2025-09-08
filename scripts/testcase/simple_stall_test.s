# シンプルなストールテスト - 確実に競合を発生させる最小限のコード
.globl  _start
.set    noreorder
.text

_start:
    # 共有メモリアドレス設定
    lui   $t2, 0x1100          # $t2 = 0x11000000（共有メモリベース）

    # 両コアが同じアドレスに同時アクセス（確実に競合発生）
    lw    $t0, 0($t2)          # 共有メモリ読み込み
    addiu $t0, $t0, 1          # インクリメント（オーバーフロー例外を避けるため addiu）
    sw    $t0, 0($t2)          # 共有メモリ書き込み

    # デバッグ用：結果を t1 に保存
    addu  $t1, $t0, $zero      # $t1 = $t0

loop:
    beq   $zero, $zero, loop
    nop
