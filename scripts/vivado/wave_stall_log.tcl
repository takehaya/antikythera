# Vivado xsim ヘッドレス用: 全信号をWDBに記録して最後まで実行（GUI不要）。
#   run_xsim_wave.sh（引数なし）から呼ばれる。生成したWDBはVNC内のVivado GUIで開ける。
log_wave -recursive /tb_stall_wave/uut/*
run all
quit
