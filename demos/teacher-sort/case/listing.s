# Mode: dual; count=10; split=5/5; UNSIGNED32
# Target-specific SLT is unsigned; NO branch/jump delay slots; JAL saves PC+4.
# All addresses are bytes. READY must initially be zero before releasing cores.
_start:
    lw     $s0, 8188($zero)                # 0000: 8c101ffc
    bne    $s0, $zero, secondary           # 0004: 16000015
# Core 0 owns initialization, input copy, merge, and COMPLETE publication.
    sw     $zero, 4096($zero)              # 0008: ac001000
    sw     $zero, 4100($zero)              # 000c: ac001004
    sw     $zero, 4104($zero)              # 0010: ac001008
    sw     $zero, 4108($zero)              # 0014: ac00100c
    addiu  $a0, $zero, 2048                # 0018: 24040800
    addiu  $a1, $zero, 4352                # 001c: 24051100
    addiu  $a2, $zero, 10                  # 0020: 2406000a
    jal    copy_words                      # 0024: 0c000022
    addiu  $t0, $zero, 1                   # 0028: 24080001
    sw     $t0, 4096($zero)                # 002c: ac081000
    addiu  $a0, $zero, 4352                # 0030: 24041100
    addiu  $a1, $zero, 5                   # 0034: 24050005
    jal    bubble_sort                     # 0038: 0c00002a
    addiu  $t0, $zero, 1                   # 003c: 24080001
    sw     $t0, 4100($zero)                # 0040: ac081004
wait_right:
    lw     $t0, 4104($zero)                # 0044: 8c081008
    beq    $t0, $zero, wait_right          # 0048: 1100fffe
    jal    merge_halves                    # 004c: 0c00003c
publish_complete:
    addiu  $t0, $zero, 1                   # 0050: 24080001
    sw     $t0, 4108($zero)                # 0054: ac08100c
    j      halt                            # 0058: 08000021
secondary:
wait_ready:
    lw     $t0, 4096($zero)                # 005c: 8c081000
    beq    $t0, $zero, wait_ready          # 0060: 1100fffe
    addiu  $a0, $zero, 4372                # 0064: 24041114
    addiu  $a1, $zero, 5                   # 0068: 24050005
    jal    bubble_sort                     # 006c: 0c00002a
    addiu  $t0, $zero, 1                   # 0070: 24080001
    sw     $t0, 4104($zero)                # 0074: ac081008
wait_complete:
    lw     $t0, 4108($zero)                # 0078: 8c08100c
    beq    $t0, $zero, wait_complete       # 007c: 1100fffe
    j      halt                            # 0080: 08000021
halt:
    j      halt                            # 0084: 08000021
# copy_words(a0=source, a1=destination, a2=count), clobbers a0/a1/a2/t0
copy_words:
    beq    $a2, $zero, copy_return         # 0088: 10c00006
copy_loop:
    lw     $t0, 0($a0)                     # 008c: 8c880000
    sw     $t0, 0($a1)                     # 0090: aca80000
    addiu  $a0, $a0, 4                     # 0094: 24840004
    addiu  $a1, $a1, 4                     # 0098: 24a50004
    addiu  $a2, $a2, -1                    # 009c: 24c6ffff
    bne    $a2, $zero, copy_loop           # 00a0: 14c0fffa
copy_return:
    jr     $ra                             # 00a4: 03e00008
# bubble_sort(a0=base, a1=count): unsigned ascending, clobbers t0..t7
# Fixed shrinking passes, no early-exit optimization; shared by all modes.
bubble_sort:
    addiu  $t7, $zero, 2                   # 00a8: 240f0002
    slt    $t6, $a1, $t7                   # 00ac: 00af702a
    bne    $t6, $zero, bubble_return       # 00b0: 15c0000e
    addiu  $t0, $a1, -1                    # 00b4: 24a8ffff
    sll    $t0, $t0, 2                     # 00b8: 00084080
    addu   $t0, $a0, $t0                   # 00bc: 00884021
bubble_outer:
    addu   $t1, $a0, $zero                 # 00c0: 00804821
bubble_inner:
    lw     $t2, 0($t1)                     # 00c4: 8d2a0000
    lw     $t3, 4($t1)                     # 00c8: 8d2b0004
    slt    $t4, $t3, $t2                   # 00cc: 016a602a
    beq    $t4, $zero, bubble_no_swap      # 00d0: 11800002
    sw     $t3, 0($t1)                     # 00d4: ad2b0000
    sw     $t2, 4($t1)                     # 00d8: ad2a0004
bubble_no_swap:
    addiu  $t1, $t1, 4                     # 00dc: 25290004
    bne    $t1, $t0, bubble_inner          # 00e0: 1528fff8
    addiu  $t0, $t0, -4                    # 00e4: 2508fffc
    bne    $t0, $a0, bubble_outer          # 00e8: 1504fff5
bubble_return:
    jr     $ra                             # 00ec: 03e00008
# Merge sorted halves into scratch, then copy back. Equality chooses left.
merge_halves:
    addiu  $t0, $zero, 4352                # 00f0: 24081100
    addiu  $t1, $zero, 4372                # 00f4: 24091114
    addiu  $t2, $zero, 4372                # 00f8: 240a1114
    addiu  $t3, $zero, 4392                # 00fc: 240b1128
    addiu  $t4, $zero, 4864                # 0100: 240c1300
merge_loop:
    beq    $t0, $t1, merge_drain_right     # 0104: 11090013
    beq    $t2, $t3, merge_drain_left      # 0108: 114b000c
    lw     $t5, 0($t0)                     # 010c: 8d0d0000
    lw     $t6, 0($t2)                     # 0110: 8d4e0000
    slt    $t7, $t6, $t5                   # 0114: 01cd782a
    bne    $t7, $zero, merge_take_right    # 0118: 15e00004
    sw     $t5, 0($t4)                     # 011c: ad8d0000
    addiu  $t0, $t0, 4                     # 0120: 25080004
    addiu  $t4, $t4, 4                     # 0124: 258c0004
    j      merge_loop                      # 0128: 08000041
merge_take_right:
    sw     $t6, 0($t4)                     # 012c: ad8e0000
    addiu  $t2, $t2, 4                     # 0130: 254a0004
    addiu  $t4, $t4, 4                     # 0134: 258c0004
    j      merge_loop                      # 0138: 08000041
merge_drain_left:
    beq    $t0, $t1, merge_copy_back       # 013c: 1109000b
    lw     $t5, 0($t0)                     # 0140: 8d0d0000
    sw     $t5, 0($t4)                     # 0144: ad8d0000
    addiu  $t0, $t0, 4                     # 0148: 25080004
    addiu  $t4, $t4, 4                     # 014c: 258c0004
    j      merge_drain_left                # 0150: 0800004f
merge_drain_right:
    beq    $t2, $t3, merge_copy_back       # 0154: 114b0005
    lw     $t6, 0($t2)                     # 0158: 8d4e0000
    sw     $t6, 0($t4)                     # 015c: ad8e0000
    addiu  $t2, $t2, 4                     # 0160: 254a0004
    addiu  $t4, $t4, 4                     # 0164: 258c0004
    j      merge_drain_right               # 0168: 08000055
merge_copy_back:
    addiu  $a0, $zero, 4864                # 016c: 24041300
    addiu  $a1, $zero, 4352                # 0170: 24051100
    addiu  $a2, $zero, 10                  # 0174: 2406000a
    j      copy_words                      # 0178: 08000022

# Fixed read-only input data in the same ROM image.
.org 0x0800
input_values:
    .word 0x00000007                       # 0800
    .word 0x00000001                       # 0804
    .word 0x00000004                       # 0808
    .word 0x00000009                       # 080c
    .word 0x00000003                       # 0810
    .word 0x00000008                       # 0814
    .word 0x00000002                       # 0818
    .word 0x00000006                       # 081c
    .word 0x00000005                       # 0820
    .word 0x00000000                       # 0824
