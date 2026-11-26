# ストール多発プログラム（波形デモ用）
#
#   両コアが同一アドレス(0x1100)へ書込ループするが、CORE_ID でループ長を変える:
#     Core0 → 3命令ループ（メモリ書込は3サイクル周期）
#     Core1 → 4命令ループ（メモリ書込は4サイクル周期）
#   周期が異なるため、両コアの書込が同じサイクルに重なる瞬間が繰り返し訪れ、
#   そのたびに Core0 優先・Core1 ストールが発生する（lockstepの自己解消を回避）。
#   → 波形で core1_stall が何度も High になる様子が見える。
#
.globl  _start
.set    noreorder
.text

_start:
    addi  $s0, $zero, 0x3000     # CORE_ID アドレス
    lw    $s0, 0($s0)            # $s0 = CORE_ID (0 or 1)
    addi  $t2, $zero, 0x1100     # 書込先（両コア同じ＝競合源）
    addi  $t3, $zero, 0          # カウンタ
    addi  $t4, $zero, 200        # 観測窓より十分多く回す
    bne   $s0, $zero, c1loop     # Core1 は別ループへ
    nop

c0loop:                          # Core0: 3命令ループ（mem 3サイクル周期）
    sw    $t3, 0($t2)
    addiu $t3, $t3, 1
    bne   $t3, $t4, c0loop
    nop
    beq   $zero, $zero, fin
    nop

c1loop:                          # Core1: 4命令ループ（mem 4サイクル周期）
    sw    $t3, 0($t2)
    addiu $t3, $t3, 1
    addiu $t3, $t3, 0            # 周期を1命令延ばすダミー
    bne   $t3, $t4, c1loop
    nop

fin:
    beq   $zero, $zero, fin      # 完了後はスピン
    nop
