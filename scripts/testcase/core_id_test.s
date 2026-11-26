# CORE_IDテスト - 各コアが自分のIDを正しく読めるか検証
# Core 0 → $t0 = 0, Core 1 → $t0 = 1 になるはず
.globl  _start
.set    noreorder
.text

_start:
    # CORE_IDを読み取る（0x3000番地）
    addi  $t2, $zero, 0x3000    # $t2 = 0x00003000
    lw    $t0, 0($t2)           # $t0 = CORE_ID (0 or 1)

    # CORE_IDを $t1 にもコピー（確認用）
    addu  $t1, $t0, $zero       # $t1 = $t0

loop:
    beq   $zero, $zero, loop
    nop
