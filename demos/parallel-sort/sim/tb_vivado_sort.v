`timescale 1ns/1ps

// リセット後、CPU自身がROMから入力をコピーし、整列を完了するまでを検証する。
`include "run_paths.vh"
// テストベンチは内部信号を観測するだけで、RAM・PC・レジスタを直接書き換えない。
module tb_vivado_sort;
    parameter DUAL = 1;
    reg clk = 0;
    always #5 clk = ~clk;
    reg reset = 1;
    integer count, metadata_handle, metadata_fields;
    string case_name, mode_name;
    integer halt_pc;
    integer limit_cycles = 200000;
    integer right_unsorted;
    // 入力・実行中のRAM・整列後の値を波形で見比べるための信号。
    reg passed = 0, initial_valid = 0, final_valid = 0;
    reg [31:0] source_values [0:63];
    reg [31:0] initial_values [0:63];
    reg [31:0] final_values [0:63];
    wire [31:0] array_words [0:63];
    integer snapshot_index;
    integer result_handle;
    integer cycles = 0, stalls1 = 0, ready_cycle = -1;
    integer halves_cycle = -1, complete_cycle = -1;
    integer left_cycle = -1, right_cycle = -1;
    integer core1_array_stores = 0, core1_done_publications = 0;
    integer core0_done_publications = 0;
    integer index, i;
    reg [31:0] expected [0:63];
    wire [31:0] pc0, pc1, memory_word;   // pc0/pc1: 各コアが実行中の命令アドレス
    wire [31:0] ready, left_done, right_done, complete; // 入力準備・左右の整列・マージ結果の書き戻し完了

    // 末尾の0/1はコア番号。この信号群は波形で競合の前後を追うために使う。
    wire req0, req1;         // 1: 共有データポートへのアクセス要求（ロードまたはストア）
    wire write0, write1;     // req=1のとき、1はストア、0はロード。書き込み許可とは別
    wire stall0, stall1;     // 1: 調停器からの待機指示。PC・レジスタを保持し、ストアも通らない
    wire [31:0] addr0, addr1, value0, value1; // addr: 要求先のバイトアドレス、value: ストアする値
    wire [31:0] debug00, debug01, debug02, debug03;
    wire [31:0] debug10, debug11, debug12, debug13;
    reg [31:0] previous_pc0, previous_pc1;
    wire [1023:0] all_regs0, all_regs1;
    reg [1023:0] previous_regs0, previous_regs1;
    reg previous_stall0, previous_stall1;

    // デモは2コア構成。比較用の1コア構成も後段で同じ観測信号に接続する。
    generate if (DUAL) begin : two
        MultiCoreCPU #(.MEM_FILE(`DEMO_PROGRAM_FILE)) dut (
            .clk(clk), .reset(reset),
            .debug_regs_core0_0(debug00), .debug_regs_core0_1(debug01),
            .debug_regs_core0_2(debug02), .debug_regs_core0_3(debug03),
            .debug_regs_core1_0(debug10), .debug_regs_core1_1(debug11),
            .debug_regs_core1_2(debug12), .debug_regs_core1_3(debug13)
        );
        for (genvar r = 0; r < 32; r = r + 1) begin : snapshot
            assign all_regs0[r*32 +: 32] = dut.cpu_core0.rf.regs[r];
            assign all_regs1[r*32 +: 32] = dut.cpu_core1.rf.regs[r];
        end
        assign pc0 = dut.core0_imem_addr;
        assign pc1 = dut.core1_imem_addr;
        assign memory_word = dut.mem_arbiter.data_memory.mem[index];
        for (genvar a = 0; a < 64; a = a + 1) begin : watch_array
            assign array_words[a] = dut.mem_arbiter.data_memory.mem[1088+a];
        end
        // RAMはワード配列。フラグのバイトアドレス0x1000は添字1024に対応する。
        assign ready = dut.mem_arbiter.data_memory.mem[1024];
        assign left_done = dut.mem_arbiter.data_memory.mem[1025];
        assign right_done = dut.mem_arbiter.data_memory.mem[1026];
        assign complete = dut.mem_arbiter.data_memory.mem[1027];
        assign stall0 = dut.core0_stall;
        assign stall1 = dut.core1_stall;
        assign req0 = dut.core0_dmem_req;
        assign req1 = dut.core1_dmem_req;
        assign write0 = dut.core0_dmem_write;
        assign write1 = dut.core1_dmem_write;
        assign addr0 = dut.core0_dmem_addr;
        assign addr1 = dut.core1_dmem_addr;
        assign value0 = dut.core0_dmem_write_data;
        assign value1 = dut.core1_dmem_write_data;
    end else begin : one
        // 比較条件では同じCPUと調停器を使い、Core 1側の要求を無効にする。
        wire ireq;
        wire [31:0] instruction, read_data;
        SimpleCPUWithMemInterface #(.CORE_ID(32'd0)) cpu (
            .clk(clk), .reset(reset), .stall(stall0),
            .dmem_req(req0), .dmem_write(write0), .dmem_addr(addr0),
            .dmem_write_data(value0), .dmem_read_data(read_data),
            .imem_req(ireq), .imem_addr(pc0), .imem_read_data(instruction),
            .reg_t0(debug00), .reg_t1(debug01), .reg_t2(debug02), .reg_t3(debug03)
        );
        SimpleMemoryArbiter #(.MEM_FILE(`DEMO_PROGRAM_FILE)) arbiter (
            .clk(clk), .reset(reset),
            .core0_dmem_req(req0), .core0_dmem_write(write0), .core0_dmem_addr(addr0),
            .core0_dmem_write_data(value0), .core0_dmem_read_data(read_data),
            .core0_imem_req(ireq), .core0_imem_addr(pc0), .core0_imem_read_data(instruction),
            .core1_dmem_req(1'b0), .core1_dmem_write(1'b0), .core1_dmem_addr(32'b0),
            .core1_dmem_write_data(32'b0), .core1_dmem_read_data(),
            .core1_imem_req(1'b0), .core1_imem_addr(32'b0), .core1_imem_read_data(),
            .core0_stall(stall0), .core1_stall()
        );
        for (genvar r = 0; r < 32; r = r + 1) begin : snapshot
            assign all_regs0[r*32 +: 32] = cpu.rf.regs[r];
        end
        assign all_regs1 = 1024'b0;
        assign pc1 = 0;
        assign memory_word = arbiter.data_memory.mem[index];
        for (genvar a = 0; a < 64; a = a + 1) begin : watch_array
            assign array_words[a] = arbiter.data_memory.mem[1088+a];
        end
        assign ready = arbiter.data_memory.mem[1024];
        assign left_done = arbiter.data_memory.mem[1025];
        assign right_done = arbiter.data_memory.mem[1026];
        assign complete = arbiter.data_memory.mem[1027];
        assign stall1 = 0;
        assign req1 = 0; assign write1 = 0;
        assign addr1 = 0; assign value1 = 0;
        assign {debug10,debug11,debug12,debug13} = 128'b0;
    end endgenerate

    // 調停で受理されたストアだけを検査し、担当範囲と同期順序の違反を検出する。
    task check_write;
        input integer core;
        input [31:0] address;
        begin
            if ((^address) === 1'bx || address[1:0] != 0)
                $fatal(1, "FAIL: core%0d invalid write address %h", core, address);
            if (!((address >= 32'h1000 && address <= 32'h100c) ||
                  (address >= 32'h1100 && address < 32'h1100 + count*4) ||
                  (address >= 32'h1300 && address < 32'h1300 + count*4)))
                $fatal(1, "FAIL: core%0d out-of-bounds write %h", core, address);
            if (DUAL && core == 1) begin
                if (ready !== 32'd1)
                    $fatal(1, "FAIL: core1 wrote before input initialization");
                if (!(address == 32'h1008 ||
                      (address >= 32'h1100+(count/2)*4 && address < 32'h1100+count*4)))
                    $fatal(1, "FAIL: core1 wrote outside its half/done flag %h", address);
            end
            if (DUAL && core == 0 && ready == 1 && left_done == 0 &&
                address >= 32'h1100 && address >= 32'h1100+(count/2)*4)
                $fatal(1, "FAIL: core0 crossed its half before publishing done");
            if (DUAL && core == 0 && address >= 32'h1300 &&
                (left_done !== 1 || right_done !== 1))
                $fatal(1, "FAIL: merge started before both halves completed");
        end
    endtask

    initial begin
        // XSimのrestartで再実行されるため、件数と期待値を再コンパイルなしで切り替えられる。
        metadata_handle = $fopen(`DEMO_METADATA_FILE, "r");
        if (!metadata_handle) $fatal(1, "FAIL: case metadata cannot be opened");
        metadata_fields = $fscanf(metadata_handle, "%d %d %d %s", count, halt_pc, right_unsorted, case_name);
        $fclose(metadata_handle);
        if (metadata_fields != 4 || (right_unsorted != 0 && right_unsorted != 1))
            $fatal(1, "FAIL: invalid case metadata");
        if (DUAL) mode_name = "dual";
        else mode_name = "single";
        $display("DEMO: case=%s mode=%s simulator runtime output follows", case_name, mode_name);
        // 入力と期待値は照合用。DUTのRAMには書き込まない。
        $readmemh(`DEMO_INPUT_FILE, source_values);
        if (count < 0 || count > 64 || halt_pc < 0 || halt_pc >= 2048)
            $fatal(1, "FAIL: invalid test metadata");
        index = 0;
        $readmemh(`DEMO_EXPECTED_FILE, expected);
        repeat (2) @(posedge clk);
        @(negedge clk); reset = 0;
        // 動作中の全コアが終了ループに入るまで、毎サイクル調停とストアを検査する。
        while (!(pc0 === halt_pc && (!DUAL || pc1 === halt_pc))) begin
            #1;
            if (cycles >= limit_cycles)
                $fatal(1, "FAIL: timeout cycles=%0d pc0=%h pc1=%h", cycles, pc0, pc1);
            if ((^pc0) === 1'bx || pc0 >= 2048 || pc0[1:0] != 0 ||
                (DUAL && ((^pc1) === 1'bx || pc1 >= 2048 || pc1[1:0] != 0)))
                $fatal(1, "FAIL: invalid program counter");
            if (stall0 !== 0 || stall1 !== (req0 && req1))
                $fatal(1, "FAIL: shared memory arbitration invariant");
            if (req0 && write0 && !stall0) begin
                check_write(0, addr0);
                if (DUAL && addr0 == 32'h1008 && value0 !== 0)
                    $fatal(1, "FAIL: core0 published core1 completion");
                if (DUAL && addr0 == 32'h1004 && value0 == 1)
                    core0_done_publications = core0_done_publications + 1;
            end
            if (req1 && write1 && !stall1) begin
                check_write(1, addr1);
                if (addr1 >= 32'h1100 && addr1 < 32'h1100 + count*4)
                    core1_array_stores = core1_array_stores + 1;
                if (addr1 == 32'h1008 && value1 == 1)
                    core1_done_publications = core1_done_publications + 1;
            end
            // 立ち上がり前の状態を控え、ストールしたコアのPCと全レジスタを更新後と比較する。
            previous_pc0 = pc0; previous_pc1 = pc1;
            previous_regs0 = all_regs0;
            previous_regs1 = all_regs1;
            previous_stall0 = stall0; previous_stall1 = stall1;
            if (stall1) stalls1 = stalls1 + 1;
            @(posedge clk); #1;
            cycles = cycles + 1;
            if (previous_stall0 && (pc0 !== previous_pc0 ||
                all_regs0 !== previous_regs0))
                $fatal(1, "FAIL: core0 changed state at stalled edge");
            if (previous_stall1 && (pc1 !== previous_pc1 ||
                all_regs1 !== previous_regs1))
                $fatal(1, "FAIL: core1 changed state at stalled edge");
            // READYの初回観測で、CPUがRAMへコピーした値を入力と照合する。
            if (ready == 1 && ready_cycle < 0) begin
                ready_cycle = cycles;
                for (snapshot_index = 0; snapshot_index < 64; snapshot_index = snapshot_index + 1) begin
                    initial_values[snapshot_index] = array_words[snapshot_index];
                    if (array_words[snapshot_index] !== source_values[snapshot_index])
                        $fatal(1, "FAIL: initialized RAM[%0d] differs from source", snapshot_index);
                end
                initial_valid = 1;
            end
            // 各段階を初めて観測したサイクルを記録する。
            if (left_done == 1 && left_cycle < 0) left_cycle = cycles;
            if (right_done == 1 && right_cycle < 0) right_cycle = cycles;
            // 各段階を初めて観測したサイクルを記録する。
            if (left_done == 1 && right_done == 1 && halves_cycle < 0) halves_cycle = cycles;
            if (complete == 1 && complete_cycle < 0) complete_cycle = cycles;
            @(negedge clk);
        end
        // 終了PCに着くだけでは合格にせず、完了通知と配列の値も照合する。
        if (complete !== 1 || (DUAL && (ready !== 1 || left_done !== 1 || right_done !== 1)))
            $fatal(1, "FAIL: termination without completed protocol");
        if (DUAL && (core0_done_publications != 1 || core1_done_publications != 1))
            $fatal(1, "FAIL: each core must publish its own completion exactly once");
        if (DUAL && right_unsorted && core1_array_stores == 0)
            $fatal(1, "FAIL: unsorted right half had no accepted core1 swap stores");
        for (i = 0; i < 64; i = i + 1) begin
            index = 32'h1100/4+i; #1;
            if (memory_word !== expected[i])
                $fatal(1, "FAIL: array[%0d] expected=%h got=%h", i, expected[i], memory_word);
        end
        // 配列・マージ領域の前後に置いたガードワードが、初期値の0のままか検査する。
        index = 32'h10fc/4; #1;
        if (memory_word !== 0) $fatal(1, "FAIL: array lower guard");
        index = 32'h1200/4; #1;
        if (memory_word !== 0) $fatal(1, "FAIL: array upper guard");
        index = 32'h12fc/4; #1;
        if (memory_word !== 0) $fatal(1, "FAIL: scratch lower guard");
        index = (32'h1300+count*4)/4; #1;
        if (memory_word !== 0) $fatal(1, "FAIL: scratch upper guard");
        for (snapshot_index = 0; snapshot_index < 64; snapshot_index = snapshot_index + 1)
            final_values[snapshot_index] = array_words[snapshot_index];
        final_valid = 1;
        if (!initial_valid) $fatal(1, "FAIL: READY input snapshot missing");
        passed = 1;
        $write("INPUT:");
        for (snapshot_index = 0; snapshot_index < count; snapshot_index = snapshot_index + 1)
            $write(" %0d", initial_values[snapshot_index]);
        $write("\nOUTPUT:");
        for (snapshot_index = 0; snapshot_index < count; snapshot_index = snapshot_index + 1)
            $write(" %0d", final_values[snapshot_index]);
        $write("\n");
        $display("PASS: sort dual=%0d n=%0d cycles=%0d stalls1=%0d ready_cycle=%0d left_done_cycle=%0d right_done_cycle=%0d halves_cycle=%0d complete_cycle=%0d post_ready_cycles=%0d core1_array_stores=%0d core1_done_publications=%0d",
            DUAL, count, cycles, stalls1, ready_cycle, left_cycle, right_cycle,
            halves_cycle, complete_cycle, complete_cycle-ready_cycle,
            core1_array_stores, core1_done_publications);
        result_handle = $fopen(`DEMO_RESULT_FILE, "w");
        if (!result_handle) $fatal(1, "FAIL: result file cannot be written");
        $fdisplay(result_handle, "PASS: case=%s mode=%s n=%0d cycles=%0d stalls1=%0d core1_array_stores=%0d", case_name, mode_name, count, cycles, stalls1, core1_array_stores);
        $fclose(result_handle);
        #20; // Keep PASS visible in the captured waveform.
        $finish;
    end
    // Vivadoの版にかかわらず波形へ追加しやすいよう、先頭10要素を個別の信号名でも公開する。
    wire [31:0] initial_00 = initial_values[0];
    wire [31:0] current_00 = array_words[0];
    wire [31:0] final_00 = final_values[0];
    wire [31:0] initial_01 = initial_values[1];
    wire [31:0] current_01 = array_words[1];
    wire [31:0] final_01 = final_values[1];
    wire [31:0] initial_02 = initial_values[2];
    wire [31:0] current_02 = array_words[2];
    wire [31:0] final_02 = final_values[2];
    wire [31:0] initial_03 = initial_values[3];
    wire [31:0] current_03 = array_words[3];
    wire [31:0] final_03 = final_values[3];
    wire [31:0] initial_04 = initial_values[4];
    wire [31:0] current_04 = array_words[4];
    wire [31:0] final_04 = final_values[4];
    wire [31:0] initial_05 = initial_values[5];
    wire [31:0] current_05 = array_words[5];
    wire [31:0] final_05 = final_values[5];
    wire [31:0] initial_06 = initial_values[6];
    wire [31:0] current_06 = array_words[6];
    wire [31:0] final_06 = final_values[6];
    wire [31:0] initial_07 = initial_values[7];
    wire [31:0] current_07 = array_words[7];
    wire [31:0] final_07 = final_values[7];
    wire [31:0] initial_08 = initial_values[8];
    wire [31:0] current_08 = array_words[8];
    wire [31:0] final_08 = final_values[8];
    wire [31:0] initial_09 = initial_values[9];
    wire [31:0] current_09 = array_words[9];
    wire [31:0] final_09 = final_values[9];

    initial begin
        // 必要なときだけ、GUIなしで確認できるVCD波形を出力する。
        if ($test$plusargs("DUMP_VCD")) begin
            $dumpfile("demo.vcd");
            $dumpvars(0, tb_vivado_sort);
        end
    end
    initial begin
        #3000000;
        $fatal(1, "FAIL: testbench timeout");
    end
endmodule
