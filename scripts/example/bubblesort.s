.globl  _start
.set    noreorder

# メモリマップ定数
.equ DATA_HEAP_BASE,    0x1100  # データメモリのヒープ開始（0x1000以上）
.equ DATA_TEMP_BASE,    0x1200  # 一時変数領域
.equ STACK_BASE,        0x10FF  # スタック開始位置

# 命令セクション
.text
_start: # main()
    # スタックポインタ初期化
    addi $sp, $zero, STACK_BASE
    
    # 配列をデータメモリにコピー
    jal copy_array_to_data_mem
    nop
    
    # ソート実行（データメモリの配列を使用）
    addi $a0, $zero, DATA_HEAP_BASE  # データメモリのベースアドレス
    move $a1, $v0                    # 要素数（copy関数から返される）
    jal  bsort
    nop
    
    # ソート結果を観察用レジスタに格納
    jal load_result_to_debug_regs
    nop

spin: # 停止用ループ
    b       spin
    nop

copy_array_to_data_mem:
    # 命令メモリ内の配列データを取得
    la   $t0, array_data
    la   $t2, array_end
    subu $t2, $t2, $t0        # 配列全体のバイト数
    srl  $t2, $t2, 2          # 要素数

    # $v0に要素数を返す（後でbsortで使用）
    move $v0, $t2

    # データメモリのヒープ領域に配列をコピー
    addi $t1, $zero, DATA_HEAP_BASE

copy_loop:
    beq  $t2, $zero, copy_done
    nop
    lw   $t3, 0($t0)
    sw   $t3, 0($t1)
    addi $t0, $t0, 4
    addi $t1, $t1, 4
    addi $t2, $t2, -1
    b    copy_loop
    nop

copy_done:
    jr   $ra
    nop

# 結果をデバッグレジスタに読み込む関数
load_result_to_debug_regs:
    # ソート済み配列の最初の4要素をデバッグレジスタ$t0-$t3に格納
    addi $t4, $zero, DATA_HEAP_BASE  # $t4 = 0x1100
    lw   $t0, 0($t4)          # 1番目の要素
    lw   $t1, 4($t4)          # 2番目の要素
    lw   $t2, 8($t4)          # 3番目の要素
    lw   $t3, 12($t4)         # 4番目の要素
    jr   $ra
    nop

# 配列データ（命令メモリの安全な位置に配置）
array_data:
    .word 7,1,4,9,3,8,2,6,5,0
array_end:

# void bsort(int *base, int n)
# レジスタ割当:
#   $a0 = base      $a1 = n
#   $t0 = endPtr    $t1 = p
#   $t2 = val1      $t3 = val2   $t4 = tmp/比較結果
bsort:
    sll     $t0, $a1, 2        # endPtr = base + n*4
    addu    $t0, $t0, $a0

outer_dec:                     # 外側ループ: 末尾が 1 要素だけになれば終了。それ以外なら内側ループを開始
    addiu   $t0, $t0, -4       # endPtr -= 4
    beq     $t0, $a0, done     # 1 要素残れば終了
    nop
    move    $t1, $a0           # p = base

inner_loop:                    # 内側ループ: p と p+1 を比較し、必要なら交換。p を次へ進め、endPtr に届くまで繰り返し
    lw      $t2, 0($t1)        # val1 = *p
    lw      $t3, 4($t1)        # val2 = *(p+1)
    slt     $t4, $t3, $t2      # val2 < val1 ?
    beq     $t4, $zero, noswap
    nop
    sw      $t3, 0($t1)        # swap
    sw      $t2, 4($t1)

noswap:
    addiu   $t1, $t1, 4        # p += 4
    bne     $t1, $t0, inner_loop
    nop
    b       outer_dec
    nop

done:
    jr      $ra
    nop
