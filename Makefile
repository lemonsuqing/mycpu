# Makefile (修正版：增加 -I$(RTL_DIR))

# --- 配置区域 ---
# 顶层模块名
TOP_MODULE = core_top

# 目录路径
RTL_DIR = rtl
TB_DIR  = tb
OBJ_DIR = obj_dir

# 源文件列表 (自动搜索 rtl 下所有的 .sv 文件)
RTL_SRCS = $(wildcard $(RTL_DIR)/*.sv)
TB_SRCS  = $(TB_DIR)/sim_main.cpp

# Verilator 编译参数
# -j 4: 使用 4 线程编译
# --trace: 开启波形追踪 
# -I$(RTL_DIR): 【修正】添加 RTL 目录为 include 搜索路径
V_FLAGS  = --cc --exe --build -j 4 -Wall --top-module $(TOP_MODULE) -I$(RTL_DIR)

# --- 规则区域 ---

# 默认目标：编译并运行
all: run

# 编译步骤
build: $(RTL_SRCS) $(TB_SRCS)
	@echo ">> Compiling Verilog..."
	verilator $(V_FLAGS) $(RTL_SRCS) $(TB_SRCS)

# 运行步骤
run: build
	@echo ">> Running Simulation..."
	@./$(OBJ_DIR)/V$(TOP_MODULE)

# 清理步骤
clean:
	rm -rf $(OBJ_dir)

.PHONY: all build run clean