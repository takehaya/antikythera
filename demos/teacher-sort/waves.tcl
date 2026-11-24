# XSim startup only sets the view. The presenter decides when to advance.
proc teacher_waves {label names radix} {
    create_wave_config $label
    foreach name $names {
        add_wave -radix $radix /tb_vivado_sort/$name
    }
}

proc teacher_view_pc {} {
    teacher_waves pc_and_stall {clk reset req0 req1 stall0 stall1 write0 write1} bin
    foreach name {pc0 pc1 addr0 addr1} {
        add_wave -radix hex /tb_vivado_sort/$name
    }
}

proc teacher_view_sync {} {
    teacher_waves synchronization {ready left_done right_done complete passed} bin
    foreach name {ready_cycle left_cycle right_cycle complete_cycle cycles} {
        add_wave -radix unsigned /tb_vivado_sort/$name
    }
}

proc teacher_view_result {} {
    teacher_waves result {initial_valid final_valid passed} bin
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
teacher_view_pc
puts {READY: original_ten / dual; simulator has not been advanced by this script.}
