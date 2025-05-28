# testcode

## sample1
```c
20080005  // 0x20080005: addi $t0, $zero, 5   => t0=5
20090003  // 0x20090003: addi $t1, $zero, 3   => t1=3
01095020  // 0x01095020: add  $t2, $t0, $t1   => t2=t0+t1=8
AC0A0000  // 0xAC0A0000: sw   $t2, 0($zero)   => Mem[0]=8
8C0B0000  // 0x8C0B0000: lw   $t3, 0($zero)   => t3=Mem[0]=8
014B5022  // 0x014B5022: sub  $t2, $t2, $t3   => t2=8-8=0 (Zero=1)
110A0002  // 0x110A0002: beq  $t0, $t2, skip  => t0=5 vs t2=0 => not equal => no branch
20080002  // 0x20080002: addi $t0, $zero, 2   => t0=2 (only runs if no branch)
08000009  // 0x08000009: j    stop            => Jump to PC=36(=9*4)
00000000  // 0x00000000: NOP
```

```c
20080005
20090003
01095020
AC0A0000
8C0B0000
014B5022
110A0002
20080002
08000009
00000000
```

```
PC の値が 0 → 4 → 8 → 12 … と進むか
命令レジスタ(Instruction)が上記の通りロードされるか（行1→2→3…）
R形式命令(行3, funct=100000) で t2に正しい加算結果が書かれるか
メモリ書き込み(sw) → メモリ[0]に8が入ったか → t3にロードできるか
Zeroフラグ: sub実行でt2=0になったとき、ALUのZeroが1になるか
beq: Zeroフラグ=1でもt0!=t2のため分岐失敗 → 次命令を実行するか
addi $t0=2 → その後Jump命令 → 行10(NOP)へ遷移するか
最終レジスタ値: $t0=2, $t1=3, $t2=0, $t3=8となっているか (そしてMemory[0]=8)
```

## sample2
```c
20080005  // 0x0000 : addi $t0,$zero,5          ; t0 = 5
2009000A  // 0x0004 : addi $t1,$zero,10         ; t1 = 10
0C000004  // 0x0008 : jal  0x0010               ; call sum()
01405820  // 0x000C : add  $t3,$t2,$zero        ; copy result
01095020  // 0x0010 : add  $t2,$t0,$t1          ; ---------- sum() ----------
03E00008  // 0x0014 : jr   $ra                  ; return
00000000  // 0x0018 : nop                       ; 以降は何もしない
00000000  // 0x001C : nop
```
```c
int t0, t1, t2, t3; 

void sum(){
    t2 = t0 + t1;
}

int main(){
    t0 = 5; // addi $t0,$zero,5
    t1 = 10;  // addi $t1,$zero,10

    sum(); // jal
    t3=t2; // add $t3,$2,$zero
}
```
```c
20080005 
2009000A
0C000004
01405820 
01095020 
03E00008 
00000000 
00000000
```
これで関数呼び出しの動作例を実験可能にした


## note
- リンクがかなり便利
  - https://www.eg.bucknell.edu/~csci320/mips_web/
  - https://rivoire.cs.sonoma.edu/cs351/wemips/
