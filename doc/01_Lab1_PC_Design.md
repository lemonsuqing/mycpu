# 01\_Lab1\_PC\_Design.md：RISC-V 处理器核心：PC 寄存器设计

### 1. 实验目标

1. 理解并实现计算机体系结构中的**程序计数器 (Program Counter, PC)**。
2. 学习 **SystemVerilog (SV)** 中的**时序逻辑 (`always_ff` / 非阻塞赋值 `<=`)** 和 **组合逻辑 (`assign`)**。
3. 掌握在 **WSL/Linux** 环境下使用 **Verilator** 进行仿真验证的基本流程和 `Makefile` 配置。
4. 解决 Verilator 不同版本间的兼容性问题（`VerilatedContext` 错误）。

### 2. RISC-V 基础理论：PC 工作原理

PC 寄存器是 CPU 中的一个 32 位寄存器，其功能是：

1. **存储地址：** 始终存储下一条要执行的指令在内存中的地址。
2. **顺序执行：** 对于 RISC-V 架构，每条指令的长度是 4 字节，因此在没有分支/跳转的情况下，PC 的值每执行完一条指令，就会自增 4 (`PC_Next = PC_Current + 4`)。
3. **复位：** 在 CPU 启动时，PC 必须被复位到一个固定的起始地址（通常是 `0x00000000`）。

### 3. 项目结构与文件 (最终)

我们将沿用您的现有结构，并确保所有文件内容是最新的、已修正的版本。

```
.
├── Makefile
├── build          # 存放构建生成的文件 (可选)
├── doc            # 存放文档 (如本手册)
├── rtl            # Register-Transfer Level (RTL) - 硬件描述文件
│   ├── core_top.sv    # 顶层模块，连接所有子模块
│   └── pc_reg.sv      # PC 寄存器模块（核心时序逻辑）
└── tb             # TestBench - 仿真测试文件
    └── sim_main.cpp   # C++ 仿真驱动程序 (Verilator Testbench)

4 directories, 4 files
```

### 4. 代码实现

#### 4.1. RTL 文件：`rtl/pc_reg.sv` (PC 寄存器模块)

这是**时序逻辑**的核心，负责存储 PC 值。

```systemverilog
// rtl/pc_reg.sv

// PC 寄存器：一个带复位和时钟的 32 位寄存器
module pc_reg (
    input  logic        clk,      // 时钟信号
    input  logic        rst,      // 复位信号 (高电平有效)
    input  logic [31:0] pc_next,  // 下一个 PC 值
    output logic [31:0] pc_out    // 当前 PC 值
);

    // always_ff 用于描述时序逻辑，即 D 触发器/寄存器
    // 敏感列表：时钟上升沿 (posedge clk) 或复位上升沿 (posedge rst)
    always_ff @(posedge clk or posedge rst) begin
        // 异步复位 (rst 信号变高时立即发生)
        if (rst) begin
            pc_out <= 32'h00000000; // PC 归零
        end 
        // 同步加载 (只有在时钟上升沿时才更新)
        else begin
            // **非阻塞赋值 (<=)**：必须用于时序逻辑
            pc_out <= pc_next;  
        end
    end

endmodule
```

#### 4.2. RTL 文件：`rtl/core_top.sv` (顶层模块)

连接 `pc_reg` 并实现 PC 的自增逻辑。

```systemverilog
// rtl/core_top.sv

module core_top (
    input  logic clk,
    input  logic rst,
    // 【重要修正】将 pc_reg 的输出提升为顶层模块的输出端口，以便在 C++ 中访问
    output logic [31:0] pc_out 
);
  
    // 内部线网声明
    logic [31:0] pc_next_w; // PC 的下一个值

    // 组合逻辑：PC 自增 4，模拟顺序执行指令
    // assign 是组合逻辑，值即时计算
    assign pc_next_w = pc_out + 32'd4; 

    // 实例化 pc_reg 模块
    pc_reg u_pc_reg (
        .clk     (clk),
        .rst     (rst),
        .pc_next (pc_next_w),
        // 连接到顶层输出端口
        .pc_out  (pc_out) 
    );

endmodule
```

#### 4.3. Testbench 文件：`tb/sim_main.cpp` (C++ 仿真程序)

采用**兼容性写法**，避免旧版 Verilator 的 `VerilatedContext` 错误。

```cpp
// tb/sim_main.cpp

#include <iostream>
// 引入 Verilator 核心头文件
#include <verilated.h>
// 引入 Verilator 自动生成的顶层模块头文件
#include "Vcore_top.h" 

// 顶层模块实例
Vcore_top* top; 

// [!!!兼容性修正!!!] 
// 1. 使用 vluint64_t 类型作为仿真时间计数器
vluint64_t main_time = 0; 
// 2. 必须实现 sc_time_stamp 函数供 Verilator 内部使用
double sc_time_stamp() {
    return main_time;
}

// 仿真时钟周期函数
void tick(int cycle_count) {
    // 模拟时钟的交替变化 (半周期)
    top->clk = 0;
    main_time++; 
    top->eval();          // 评估组合逻辑和时钟下降沿逻辑

    // 模拟时钟的交替变化 (半周期)
    top->clk = 1;
    main_time++; 
    top->eval();          // 评估时钟上升沿逻辑 (寄存器在此刻更新)
  
    // 打印 PC 的值
    printf("Cycle %d: PC = 0x%08X\n", cycle_count, top->pc_out); 
}

int main(int argc, char** argv) {
  
    // [!!!兼容性修正!!!] 使用 Verilated 静态方法进行初始化
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true); // 开启波形追踪 (下一课用到)

    // 实例化顶层模块
    // [!!!修正!!!] 实例化时不再需要传入 contextp 
    top = new Vcore_top("top"); 

    // 1. 复位阶段 (Reset Phase)
    top->rst = 1; // 拉高复位
    top->clk = 0;
    top->eval(); 
    printf("--- Start Reset ---\n");
    // 复位时，由于 pc_reg 是异步复位，eval() 后 PC 应该立即为 0
    printf("Initial PC = 0x%08X\n", top->pc_out); 

    tick(0); // 运行一个周期，观察复位状态

    top->rst = 0; // 释放复位信号
    printf("--- Reset Released ---\n");

    // 2. 运行阶段 (Run Phase)
    for (int i = 1; i <= 5; ++i) {
        tick(i); // PC 应该开始自增
    }
    printf("--- Simulation Finished ---\n");

    // 清理
    delete top;
    return 0;
}
```

#### 4.4. `Makefile`

您的 `Makefile` 已经很完善，保持不变：

```makefile
# Makefile (保持不变)

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
# --trace: 开启波形追踪 (现在已在 C++ 中用 Verilated::traceEverOn(true) 替代)
V_FLAGS  = --cc --exe --build -j 4 -Wall --top-module $(TOP_MODULE)

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
	rm -rf $(OBJ_DIR)

.PHONY: all build run clean
```

### 5. 实验验证

在项目根目录执行 `make clean`，然后执行 `make`。

**预期输出：**

```
>> Compiling Verilog...
... (Verilator 和 g++ 编译信息) ...
>> Running Simulation...
--- Start Reset ---
Initial PC = 0x00000000
Cycle 0: PC = 0x00000000
--- Reset Released ---
Cycle 1: PC = 0x00000004
Cycle 2: PC = 0x00000008
Cycle 3: PC = 0x0000000C
Cycle 4: PC = 0x00000010
Cycle 5: PC = 0x00000014
--- Simulation Finished ---
```
