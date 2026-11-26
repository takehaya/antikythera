# 起動時は波形の設定だけを行う。シミュレーション時間は run で進める。
proc demo_waves {label names radix} {
    create_wave_config $label
    foreach name $names {
        add_wave -radix $radix /tb_vivado_sort/$name
    }
}

# 両コアのメモリ要求とストール、PCを並べて競合の前後を見る。
proc demo_view_pc {} {
    demo_waves pc_and_stall {clk reset req0 req1 stall0 stall1 write0 write1} bin
    foreach name {pc0 pc1 addr0 addr1} {
        add_wave -radix hex /tb_vivado_sort/$name
    }
}

# 初期化から左右の整列完了、マージ完了までをフラグで追う。
proc demo_view_sync {} {
    demo_waves synchronization {ready left_done right_done complete passed} bin
    foreach name {ready_cycle left_cycle right_cycle complete_cycle cycles} {
        add_wave -radix unsigned /tb_vivado_sort/$name
    }
}

# 入力と出力の各要素、検査の合否とサイクル数を表示する。
proc demo_view_result {} {
    demo_waves result {initial_valid final_valid passed} bin
    foreach prefix {initial final} {
        for {set i 0} {$i < 10} {incr i} {
            add_wave -radix unsigned /tb_vivado_sort/${prefix}_[format %02d $i]
        }
    }
    foreach name {cycles stalls1 core1_array_stores} {
        add_wave -radix unsigned /tb_vivado_sort/$name
    }
}

log_wave -r /
demo_view_pc
puts {READY: simulator has not been advanced by this script.}
