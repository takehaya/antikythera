# デュアルコアCPU設計ドキュメント

## 概要

このドキュメントでは、既存のシングルコアMIPS CPU（Antikythera）をベースに、メモリ競合時のストール機能付きデュアルコアシステムに拡張した設計について説明します。

## 設計目標

1. **最小限の変更**：既存のSingleCycleCPUアーキテクチャを可能な限り保持
2. **メモリ競合制御**：データメモリと命令メモリへの同時アクセス時のストール機能
3. **シンプルな優先制御**：コア0優先の固定優先度調停
4. **既存リソース活用**：DataMemory、InstructionMemoryをそのまま使用

## システムアーキテクチャ

```
MultiCoreCPU (トップレベル)
├── SimpleCPUWithMemInterface (コア0)
├── SimpleCPUWithMemInterface (コア1)  
├── SimpleMemoryArbiter (メモリ調停器)
│   ├── DataMemory (既存)
│   └── InstructionMemory (既存)
```

## 主要コンポーネント

### 1. MultiCoreCPU (`multicore_cpu.v`)
- **役割**: システム全体のトップレベルモジュール
- **機能**: 2つのCPUコアと1つの調停器を統合
- **インタフェース**: デバッグレジスタ出力のみ

### 2. SimpleMemoryArbiter (`simple_memory_arbiter.v`) 
- **役割**: メモリアクセスの調停とストール制御
- **調停方式**: コア0固定優先
- **対象**: データメモリ、命令メモリの両方
- **ストール条件**: 同一メモリへの同時アクセス時

### 3. SimpleCPUWithMemInterface (`simple_cpu_with_mem_interface.v`)
- **役割**: メモリリクエストインタフェース付きCPU
- **ベース**: 既存のSingleCycleCPU
- **追加機能**: ストール対応、メモリリクエスト信号生成

### 4. テストベンチ (`tb_multicore_cpu.v`)
- **役割**: デュアルコア動作の検証
- **モニタ機能**: ストール状況、メモリリクエスト、レジスタ状態

## メモリアクセスワークフロー

### 通常時（競合なし）
```
1. コア0: 命令フェッチ要求 → imem_req=1
2. コア1: データアクセス要求 → dmem_req=1
3. 調停器: 異なるメモリなので両方許可
4. 各メモリ: 同時アクセス実行
5. 結果: ストールなし、正常動作
```

### 競合時（データメモリ）
```
1. コア0: lw $t0, 0($sp) → dmem_req=1
2. コア1: sw $t1, 4($sp) → dmem_req=1  
3. 調停器: 競合検出、コア0優先
4. コア0: アクセス許可 → dmem_grant=1
5. コア1: ストール → core1_stall=1
6. 次サイクル: コア1がアクセス実行
```

### 競合時（命令メモリ）
```
1. 両コア: 命令フェッチ → imem_req=1
2. 調停器: コア0優先でアクセス許可
3. コア0: 命令取得、実行継続  
4. コア1: PC更新停止、現在命令を保持
5. 次サイクル: コア1が命令フェッチ実行
```

## CPU差分解説：cpu.v vs simple_cpu_with_mem_interface.v

### 主要な違い

#### 1. モジュールインタフェース
**元のCPU (cpu.v)**:
```verilog
module SingleCycleCPU(
    input clk, reset,
    output [31:0] reg_t0, reg_t1, reg_t2, reg_t3
);
```

**新しいCPU (simple_cpu_with_mem_interface.v)**:
```verilog
module SimpleCPUWithMemInterface(
    input clk, reset,
    input stall,  // 調停器からのストール信号
    
    // データメモリインタフェース
    output reg dmem_req, dmem_write,
    output reg [31:0] dmem_addr, dmem_write_data,
    input [31:0] dmem_read_data,
    
    // 命令メモリインタフェース  
    output reg imem_req,
    output reg [31:0] imem_addr,
    input [31:0] imem_read_data,
    
    output [31:0] reg_t0, reg_t1, reg_t2, reg_t3
);
```

#### 2. メモリアクセス方式

**元のCPU**: 直接メモリアクセス
```verilog
// 命令メモリ
InstructionMemory imem (
    .PC(PC),
    .Instruction(Instruction)  
);

// データメモリ
DataMemory dmem (
    .clk(clk),
    .MemWrite(MemWrite),
    .Address(ALUResult),
    ...
);
```

**新しいCPU**: リクエスト・レスポンス方式
```verilog
// 命令メモリアクセス
always @(*) begin
    imem_req = 1'b1;  // 常に命令を要求
    imem_addr = PC;
end
wire [31:0] Instruction = imem_read_data;

// データメモリアクセス  
always @(*) begin
    if (MemRead || MemWrite) begin
        dmem_req = 1'b1;
        dmem_write = MemWrite;
        dmem_addr = ALUResult;
        dmem_write_data = regData2;
    end
end
```

#### 3. ストール対応

**元のCPU**: ストール機能なし
```verilog
// PC更新
always @(posedge clk) begin
    if(reset) PC <= 0;
    else      PC <= PCnext;
end
```

**新しいCPU**: ストール時PC保持
```verilog  
// PC更新（ストール時は更新しない）
always @(posedge clk) begin
    if(reset) 
        PC <= 0;
    else if (!stall)  // ストール中でない場合のみPC更新
        PC <= PCnext;
    // ストール中はPCを維持
end

// レジスタ書き込みもストール中は無効
.RegWrite(RegWrite && !stall)
```

## 設計上の特徴

### 利点
1. **既存資源活用**: DataMemoryとInstructionMemoryを変更不要
2. **シンプル制御**: 固定優先度で複雑な調停不要
3. **最小オーバーヘッド**: 真の競合時のみストール
4. **デバッグ容易**: 各コア独立動作

### 制限事項
1. **命令フェッチ競合**: 毎サイクル発生可能（50%ストール率）
2. **固定優先度**: コア1の性能低下の可能性
3. **スケーラビリティ**: 2コア専用設計

### 改善案
1. **ラウンドロビン調停**: 優先度を交互に切り替え
2. **デュアルポートメモリ**: ハードウェアレベルでの並行アクセス
3. **命令キャッシュ**: 命令フェッチ競合の軽減

## 検証戦略

テストベンチでは以下の項目を監視：
- メモリリクエスト状況
- ストール発生頻度
- 各コアのレジスタ状態
- アクセス競合パターン

この設計により、教育目的に適した理解しやすいデュアルコアシステムを実現しています。