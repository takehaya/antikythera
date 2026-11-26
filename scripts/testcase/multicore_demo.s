# マルチコア動作デモ
#
#   2つのコアが「同一プログラム」を実行し、CORE_ID で別々の仕事を並列に行うことを示す。
#     - lw 0x3000 で自分の CORE_ID を取得（Core0=0 / Core1=1）
#     - 書き込み先 = 0x1100 + CORE_ID*0x100  → Core0: 0x1100 / Core1: 0x1200
#     - 値 value[i] = (CORE_ID<<8) + i        → Core0: {0,1,2,3,4} / Core1: {256,...,260}
#       （値の上位バイト = 自分の CORE_ID。どちらのコアが書いたか一目で分かる）
#     - 完了フラグ: 0x2000 + CORE_ID*4 に 1 を書く（Core0:0x2000 / Core1:0x2004）
#
#   「マルチコアが動く」証明:
#     1コアだけならその ID 側の領域しか埋まらない。両領域(0x1100 と 0x1200)が
#     正しく埋まっている = 2コアが各自の CORE_ID 分岐を並列に実行した、ということ。
#
.globl  _start
.set    noreorder
.text

_start:
    addi  $s0, $zero, 0x3000     # CORE_ID 特殊アドレス
    lw    $s0, 0($s0)            # $s0 = CORE_ID (0 or 1)

    sll   $t1, $s0, 8            # $t1 = CORE_ID << 8  (=0 or 256=0x100)
    addi  $t0, $zero, 0x1100     # 書き込み先ベース
    addu  $t0, $t0, $t1          # $t0 = 0x1100 + CORE_ID*0x100

    # value[i] = (CORE_ID<<8) + i を 5 個書く（アンロール）
    addiu $t3, $t1, 0
    sw    $t3, 0($t0)
    addiu $t3, $t1, 1
    sw    $t3, 4($t0)
    addiu $t3, $t1, 2
    sw    $t3, 8($t0)
    addiu $t3, $t1, 3
    sw    $t3, 12($t0)
    addiu $t3, $t1, 4
    sw    $t3, 16($t0)

    # 完了フラグ: 0x2000 + CORE_ID*4 に 1
    sll   $t5, $s0, 2            # CORE_ID * 4
    addi  $t6, $zero, 0x2000
    addu  $t6, $t6, $t5          # Core0:0x2000 / Core1:0x2004
    addi  $t4, $zero, 1
    sw    $t4, 0($t6)

done:
    beq   $zero, $zero, done     # 完了後はスピン
    nop
