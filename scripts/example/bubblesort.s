.globl  _start
.set    noreorder

# dataセクション
.data
arr:
    .word 7,1,4,9,3,8,2,6,5,0
arr_end: 

# 命令セクション
.text
_start: # main()
    # $a0 = base
    la      $a0, arr

    # $a1 = 要素数 = (arr_end - arr) / 4
    la      $t0, arr_end
    subu    $t0, $t0, $a0      # バイト長
    srl     $a1, $t0, 2        # len = bytesize/4 → 要素数

    jal     bsort
    nop

spin: # 停止用ループ
    b       spin
    nop

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
