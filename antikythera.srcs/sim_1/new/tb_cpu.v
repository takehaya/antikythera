`timescale 1ns/1ps
module tb_SingleCycleCPU();

reg clk = 0;
reg reset = 1;
wire [31:0] t0, t1, t2, t3;

// デバッグ用ループ変数
integer i;

SingleCycleCPU uut (
    .clk(clk),
    .reset(reset),
    .reg_t0(t0),
    .reg_t1(t1),
    .reg_t2(t2),
    .reg_t3(t3)
);

// クロック生成 (10ns周期)
always #5 clk = ~clk;

// メモリダンプタスク
task dump_memory_range;
    input [31:0] start_addr;
    input [31:0] end_addr;
    input [255:0] label;  // ラベル用の文字列
    integer addr, word_index;
    begin
        $display("\n=== %s: 0x%h - 0x%h ===", label, start_addr, end_addr);
        for (addr = start_addr; addr <= end_addr; addr = addr + 4) begin
            word_index = addr / 4;
            $display("addr[0x%h] = %d (0x%h)", addr, 
                     uut.dmem.mem[word_index], uut.dmem.mem[word_index]);
        end
        $display("=== End of %s ===", label);
    end
endtask

// 配列状態表示タスク
task display_array_status;
    input [255:0] timing_label;
    integer idx;
    begin
        $display("\n[%s] ソート配列の状態:", timing_label);
        $write("配列: ");
        for (idx = 1088; idx < 1098; idx = idx + 1) begin  // 0x1100/4=1088から10要素
            $write("%d ", uut.dmem.mem[idx]);
        end
        $display("");
        $display("デバッグレジスタ: t0=%d t1=%d t2=%d t3=%d", t0, t1, t2, t3);
        $display("現在のPC: 0x%h, 命令: 0x%h", uut.PC, uut.Instruction);
    end
endtask

initial begin
    #21;       // リセットを少し維持
    reset = 0; // CPUスタート
    
    $display("=== バブルソートシミュレーション開始 ===");
    
    // 命令メモリの初期化状態を確認
    $display("\n=== 命令メモリ初期化確認 ===");
    $display("PC=0の命令: 0x%h", uut.imem.mem[0]);
    $display("PC=4の命令: 0x%h", uut.imem.mem[1]);
    $display("PC=8の命令: 0x%h", uut.imem.mem[2]);
    
    // 新しいbubblesort.sの命令パターンかチェック
    if (uut.imem.mem[0] == 32'h201d00ff && uut.imem.mem[1] == 32'h0c00000b) begin
        $display("✓ 新しいbubblesort.sが正しく読み込まれています");
    end else begin
        $display("✗ 古いメモリファイルが使用されている可能性があります");
    end
    
    if (uut.imem.mem[0] === 32'hxxxxxxxx) begin
        $display("ERROR: 命令メモリが初期化されていません！");
        $display("memfile_I.datの読み込みに失敗している可能性があります。");
    end else begin
        $display("OK: 命令メモリは正常に初期化されています。");
    end
    
    // 段階的な観察
    #200;
    display_array_status("200ns後");
    
    #800;  // 合計1000ns
    display_array_status("1000ns後");
    
    #4000; // 合計5000ns
    display_array_status("5000ns後");
    
    #20000; // 合計25000ns
    display_array_status("25000ns後");
    
    // 詳細なメモリダンプ
    dump_memory_range(32'h1100, 32'h1124, "ソート結果配列");
    
    // コピー元のデータメモリアドレスも確認（本来は空であるべき）
    dump_memory_range(32'h90, 32'hC0, "コピー元とされるデータメモリ領域");
    
    // 実際の配列データがある命令メモリの確認
    $display("\n=== 命令メモリ vs データメモリの比較 ===");
    $display("命令メモリ[37-46]の配列データ:");
    for (i = 37; i < 47; i = i + 1) begin
        $display("  imem[%d] = %d", i, uut.imem.mem[i]);
    end
    $display("データメモリ[37-46]の内容:");
    for (i = 37; i < 47; i = i + 1) begin
        $display("  dmem[%d] = %d", i, uut.dmem.mem[i]);
    end
    
    // 命令メモリの内容も確認（デバッグ用）
    $display("\n=== 命令メモリの配列データ領域確認 ===");
    for (i = 35; i < 50; i = i + 1) begin  // 実際の配列データ位置
        $display("imem[%d] = 0x%h (%d)", i, uut.imem.mem[i], uut.imem.mem[i]);
    end
    
    // 最終結果の確認
    $display("\n=== 最終結果検証 ===");
    $display("期待値: 0 1 2 3 4 5 6 7 8 9");
    $write("実際値: ");
    for (i = 1088; i < 1098; i = i + 1) begin
        $write("%d ", uut.dmem.mem[i]);
    end
    $display("");
    
    $display("\n=== シミュレーション完了 ===");
    $stop;
end

// PC値変化の詳細モニタリング
initial begin
    #25; // reset解除後から開始
    $display("=== PC値変化の詳細トレース ===");
    repeat(20) begin
        #10;
        $display("Time=%0t: PC=0x%h, Inst=0x%h", $time, uut.PC, uut.Instruction);
    end
end

endmodule
