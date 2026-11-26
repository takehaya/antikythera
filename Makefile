# Antikythera - Makefile
# アセンブリのビルドとIverilogシミュレーションを行う

# ディレクトリ
SRC_DIR    := antikythera.srcs/source_1/new
TB_DIR     := antikythera.srcs/sim_1/new
TC_DIR     := scripts/testcase
BUILD_DIR  := build

# ツール
IVERILOG   := iverilog
VVP        := vvp -n
MIPS2HEX   := bash scripts/mips2hex.sh
IV_FLAGS   := -g2012

# Verilogソース（共通モジュール）
COMMON_SRC := \
	$(SRC_DIR)/alu.v \
	$(SRC_DIR)/alu_control.v \
	$(SRC_DIR)/main_control.v \
	$(SRC_DIR)/register.v \
	$(SRC_DIR)/sign_extender.v \
	$(SRC_DIR)/zero_extender.v \
	$(SRC_DIR)/instaction_memory.v \
	$(SRC_DIR)/data_memory.v

# マルチコア用ソース
MULTICORE_SRC := $(COMMON_SRC) \
	$(SRC_DIR)/simple_cpu_with_mem_interface.v \
	$(SRC_DIR)/simple_memory_arbiter.v \
	$(SRC_DIR)/multicore_cpu.v

# シングルコア用ソース
SINGLECORE_SRC := $(COMMON_SRC) \
	$(SRC_DIR)/cpu.v

# アセンブリソース → .dat ファイル
ASM_SRCS := $(wildcard $(TC_DIR)/*.s)
DAT_FILES := $(patsubst $(TC_DIR)/%.s,$(BUILD_DIR)/testcase/%.dat,$(ASM_SRCS))

# ==== メインターゲット ====

.PHONY: all clean asm sim-stall sim-multicore sim-cpu help

all: asm ## 全アセンブリをビルド

help: ## ヘルプを表示
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ==== アセンブリビルド ====

asm: $(DAT_FILES) ## 全 .s → .dat をビルド

$(BUILD_DIR)/testcase/%.dat: $(TC_DIR)/%.s scripts/mips2hex.sh
	mkdir -p $(dir $@)
	$(MIPS2HEX) "$<" "$@"

# ==== シミュレーション ====

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

sim-stall: $(BUILD_DIR) ## ストール検証テストを実行
	$(IVERILOG) $(IV_FLAGS) -o $(BUILD_DIR)/sim_stall \
		$(TB_DIR)/tb_stall_verification.v $(MULTICORE_SRC)
	$(VVP) $(BUILD_DIR)/sim_stall

sim-multicore: $(BUILD_DIR) ## マルチコアCPUテストを実行（memfile_I.dat を指定: make sim-multicore DAT=path/to/file.dat）
	$(IVERILOG) $(IV_FLAGS) -o $(BUILD_DIR)/sim_multicore \
		$(TB_DIR)/tb_multicore_cpu.v $(MULTICORE_SRC)
	cp "$(if $(DAT),$(DAT),$(TC_DIR)/multicore_demo.dat)" "$(BUILD_DIR)/memfile_I.dat"
	cd "$(BUILD_DIR)" && $(VVP) sim_multicore

sim-cpu: $(BUILD_DIR) ## シングルコアCPUテストを実行
	$(IVERILOG) $(IV_FLAGS) -o $(BUILD_DIR)/sim_cpu \
		$(TB_DIR)/tb_cpu.v $(SINGLECORE_SRC)
	cp "$(if $(DAT),$(DAT),$(TC_DIR)/single_bubblesort.dat)" "$(BUILD_DIR)/memfile_I.dat"
	cd "$(BUILD_DIR)" && $(VVP) sim_cpu

# ==== クリーン ====

clean: ## ビルド成果物を削除
	rm -rf $(BUILD_DIR)
