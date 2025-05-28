.globl  _start
.set    noreorder
_start:
    addi    $t0,$zero,5   # 20080005
    addi    $t1,$zero,10  # 2009000A
    jal     sum           # 0C000004  (リンクは ld が解決)
    add     $t3,$t2,$zero # 01405820

sum:
    add     $t2,$t0,$t1   # 01095020
    jr      $ra           # 03E00008
    nop                   # アライメント用 00000000
