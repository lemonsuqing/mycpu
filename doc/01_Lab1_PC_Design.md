# Lab 1: 程序计数器 (Program Counter) 设计与验证手册

**创建日期**: 2025年
**实验目标**: 设计一个带跳转功能的 32位 PC 模块，并建立基于 Verilator + C++ 的仿真环境。

---

## 1. 实验背景与原理

### 1.1 什么是 PC？

程序计数器 (PC) 是 CPU 的“导航仪”。它是一个 32 位的寄存器，存储着**当前正在执行的指令在内存中的地址**。

### 1.2 核心逻辑

PC 的行为遵循以下规则：

1. **复位 (Reset)**: 系统启动或按下复位键时，PC 被强制设为初始值 (通常是 `0x00000000` 或 `0x80000000`)。
2. **顺序执行 (Sequential)**: 在正常情况下，每执行完一条指令，PC = PC + 4 (因为 RISC-V 指令长度为 4 字节)。
3. **跳转 (Branch/Jump)**: 当遇到 `JAL`, `BEQ` 等跳转指令时，PC 需要直接更新为目标地址 (`Target Address`)。

### 1.3 硬件电路模型 (Schematic View)

在硬件层面，PC 并非软件变量，而是一个由 **多路选择器 (MUX)**、**加法器 (Adder)** 和 **D触发器 (D-Flip-Flop)** 组成的闭环电路。

```text
       跳转地址 (Jump Addr)
              |
              v
      +---------------+
      |      MUX      | <---- 跳转使能 (Jump En)
      +-------+-------+
              | 
              | next_pc (组合逻辑计算出的下一跳)
              v
      +---------------+
      |  PC Register  | <---- 时钟 (CLK) & 复位 (RST)
      | (D-Flip-Flop) |
      +-------+-------+
              |
   +----------+----------> 输出当前 PC (Current PC)
   |          |
   |      +-------+
   |      | Adder |
   +----->|  + 4  |
          +-------+
              |
              v
       (PC+4) 回到 MUX
```

---

## 2. 目录结构

我们在 `~/study/cpu_study/mycpu/` 下采用标准的 IC 工程结构：

```text
mycpu/
├── rtl/            # [Design] SystemVerilog 源码
│   └── pc_reg.sv   # PC 模块
├── tb/             # [Testbench] 测试平台
│   └── sim_main.cpp # C++ 仿真主程序
├── obj_dir/        # [Output] 编译产物 (自动生成)
└── doc/            # [Document] 文档
    └── 01_Lab1_PC_Design.md
```

---

## 3. RTL 实现 (SystemVerilog)

文件：`rtl/pc_reg.sv`

采用经典的**两段式写法**：一段组合逻辑计算 `next_pc`，一段时序逻辑更新 `pc`。

```systemverilog
module pc_reg (
    input  logic        clk,        // 时钟
    input  logic        rst_n,      // 低电平复位
    input  logic        jump_en,    // 跳转信号 (1=跳转)
    input  logic [31:0] jump_addr,  // 跳转目标地址
  
    output logic [31:0] pc          // 当前 PC 值
);

    logic [31:0] next_pc;

    // --- 1. 组合逻辑: 决策大脑 ---
    // 描述 MUX 和 Adder 的逻辑
    // 使用阻塞赋值 (=)
    always_comb begin
        if (jump_en) begin
            next_pc = jump_addr;
        end else begin
            next_pc = pc + 4;
        end
    end

    // --- 2. 时序逻辑: 状态记忆 ---
    // 描述 D触发器
    // 使用非阻塞赋值 (<=)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'h0;
        end else begin
            pc <= next_pc;
        end
    end

endmodule
```

### 关键知识点

* **`logic`**: 替代了旧 Verilog 的 `reg` 和 `wire`，自动推断类型。
* **`always_comb` vs `always_ff`**: 明确区分纯逻辑运算和寄存器存储。
* **`<=` (非阻塞赋值)**: 时序逻辑必须用这个，保证并行电路状态更新的同步性。

---

## 4. 验证环境 (C++ & Verilator)

我们使用 C++ 来驱动硬件模型。

文件：`tb/sim_main.cpp`

```cpp
#include "Vpc_reg.h"
#include "verilated.h"
#include <cstdio>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vpc_reg* top = new Vpc_reg;

    // 模拟 10 个时钟周期
    for (int i = 0; i < 10; i++) {
        // 1. 模拟时钟低电平
        top->clk = 0; 
        top->eval(); 

        // 2. 模拟时钟高电平 (上升沿) -> 寄存器在此刻更新
        top->clk = 1; 
        top->eval(); 

        printf("Time %d: PC = 0x%08x\n", i, top->pc);

        // --- 测试激励 ---
        if (i < 2) {
            top->rst_n = 0; // 复位保持两个周期
        } else {
            top->rst_n = 1; // 释放复位
        }

        // 在第5周期触发跳转
        if (i == 5) {
            top->jump_en = 1;
            top->jump_addr = 0x1234;
            printf("  [Jump Signal] -> 0x1234\n");
        } else {
            top->jump_en = 0;
        }
    }

    delete top;
    return 0;
}
```

---

## 5. 编译与运行

### 5.1 编译命令

在 `mycpu` 根目录下运行：

```bash
verilator --cc --exe --build -j 4 -Wall \
  rtl/pc_reg.sv tb/sim_main.cpp \
  --top-module pc_reg
```

### 5.2 运行仿真

```bash
./obj_dir/Vpc_reg
```

### 5.3 预期输出

```text
Time 0: PC = 0x00000000
Time 1: PC = 0x00000000
Time 2: PC = 0x00000004  <-- 复位结束，开始计数
Time 3: PC = 0x00000008
...
  [Jump Signal] -> 0x1234
Time 6: PC = 0x00001234  <-- 跳转成功
Time 7: PC = 0x00001238  <-- 继续顺序执行
```

---

## 6. 避坑指南 (Troubleshooting)

### 坑点 1：Verilator 的 `-j` 参数报错

* **现象**: 使用 `-j 0` 时报错 `%Error: -j accepts positive integer`.
* **原因**: 旧版本或特定版本的 Verilator 不支持用 `0` 自动检测核心数。
* **解决**: 手动指定核心数，如 `-j 1` 或 `-j 4`。

### 坑点 2：复位信号的延时生效

* **现象**: 在 C++ 代码中 `rst_n = 1` 后，PC 没有立刻变。
* **原理**: 硬件是边沿触发的。如果在 `eval()` (时钟沿) 发生时 `rst_n` 还是 0，那么这一拍还是复位状态。必须等到下一个时钟沿，电路才能“看到”复位已经变成了 1。

### 坑点 3：VS Code 插件

* **建议**: 必须安装 `Verilog-HDL/SystemVerilog` 插件，并且如果是 WSL 环境，必须点击 "Install in WSL"。否则代码全是白色，无法检查语法。

---
