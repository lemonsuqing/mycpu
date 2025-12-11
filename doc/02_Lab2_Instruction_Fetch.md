# Lab 2: 取指阶段 (Instruction Fetch) 设计手册

**前置要求**: 完成 Lab 1 (PC Design)
**实验目标**: 实现指令存储器 (IMem)，并将其与 PC 连接，完成 CPU 的取指功能，并引入 Makefile 管理工程。

---

## 1. 实验原理

### 1.1 冯·诺依曼架构简述

在经典架构中，CPU 执行指令的第一步是 **Fetch (取指)**：根据 PC 的地址，从内存拿指令。

### 1.2 核心电路连接图

我们需要构建如下的电路结构：

```text
       +-------------+                  +--------------+
       |             |   地址 (Address) |              |
       |   PC_REG    | ---------------->|     IMEM     |
       |  (Lab 1)    |                  |    (Lab 2)   |
       |             |                  |              |
       +-------------+                  +-------+------+
                                                |
                                                | 指令数据 (Instruction)
                                                v
                                          (去往下一级译码器)
```

### 1.3 关键概念：字节寻址 vs 字对齐

* **RISC-V 规范**: 内存地址以 **Byte (8-bit)** 为单位。
* **硬件实现**:
  * PC 步长为 4 (0, 4, 8, 12...)。
  * 内存数组 `RAM` 索引步长为 1 (0, 1, 2, 3...)。
  * **映射公式**: `RAM_Index = PC >> 2` (即 `PC / 4`)。

---

## 2. RTL 实现

### 2.1 指令存储器 (`rtl/imem.sv`)

为了验证方便，我们使用 SystemVerilog 数组模拟 ROM，并在 `initial` 块中硬编码机器码。
**注意**: 添加了 `lint_off` 指令以屏蔽未使用信号的警告。

```systemverilog
/* verilator lint_off UNUSED */
module imem (
    input  logic [31:0] raddr,  // 也就是 PC
    output logic [31:0] rdata   // 取出的指令
);
    // 定义 16 个 32位宽的存储空间
    logic [31:0] RAM [0:15];

    initial begin
        // 这里存放的是真实的 RISC-V 机器码
        RAM[0] = 32'h00000013; // nop
        RAM[1] = 32'h00100093; // addi x1, x0, 1
        RAM[2] = 32'h00208133; // add  x2, x1, x0
        RAM[3] = 32'hdeadbeef; // 标志位
        RAM[4] = 32'h00000000;
        // ... 其余默认为 0
    end

    // 地址映射：忽略低2位，取高位作为索引
    // raddr[5:2] 对应 (PC / 4) % 16
    assign rdata = RAM[raddr[5:2]];

endmodule
/* verilator lint_on UNUSED */
```

### 2.2 顶层连接 (`rtl/core_top.sv`)

创建一个顶层模块将 PC 和 IMem 连接起来。

```systemverilog
module core_top (
    input  logic        clk,
    input  logic        rst_n,
    output logic [31:0] instr,
    output logic [31:0] pc
);
    logic [31:0] pc_wire; // 内部连线：PC输出 -> IMem输入

    // 实例化 PC
    pc_reg u_pc_reg (
        .clk(clk), .rst_n(rst_n),
        .jump_en(1'b0), .jump_addr(32'b0),
        .pc(pc_wire)
    );

    // 实例化 IMem
    imem u_imem (
        .raddr(pc_wire),
        .rdata(instr)
    );
  
    assign pc = pc_wire;
endmodule
```

---

## 3. 验证与运行

### 3.1 仿真代码 (`tb/sim_main.cpp`)

重点是引入新的头文件 `Vcore_top.h`。

```cpp
#include "Vcore_top.h"
#include "verilated.h"
#include <cstdio>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vcore_top* top = new Vcore_top;

    for (int i = 0; i < 10; i++) {
        top->clk = 0; top->eval();
        top->clk = 1; top->eval();

        printf("Time %d: PC = 0x%08x, Instr = 0x%08x\n", 
               i, top->pc, top->instr);

        if (i < 2) top->rst_n = 0;
        else       top->rst_n = 1;
    }
    delete top;
    return 0;
}
```

### 3.2 编译与运行 (Makefile)

使用新建的 `Makefile` 进行自动化构建。

```bash
# 在 mycpu 根目录下运行
make
```

### 3.3 预期结果

```text
Time 0: PC = 0x00000000, Instr = 0x00000013 (复位中)
...
Time 3: PC = 0x00000004, Instr = 0x00100093
Time 4: PC = 0x00000008, Instr = 0x00208133
Time 5: PC = 0x0000000c, Instr = 0xdeadbeef
```

---

## 4. 常见问题与解决方案

### Q1: UNUSED 警告

* **现象**: `%Warning-UNUSED: ... Bits of signal are not used: 'raddr'[31:6,1:0]`
* **原因**: PC 传来了 32 位地址，但 IMem 很小，只用了其中 4 位。Verilator 认为这是潜在 Bug。
* **解决**: 在 `imem.sv` 文件首尾添加 `/* verilator lint_off UNUSED */` 显式告诉工具忽略此模块的此类警告。

### Q2: 为什么 Time 2 的 PC 还是 0？

* **原因**: 复位信号 `rst_n` 在 C++ 代码中是在 Time 2 循环结束时才置为 1 的。硬件在 Time 2 的上升沿看到的还是低电平复位信号。

### Q3: 为什么用 Makefile？

* **原因**: 随着文件增多，手动输入 `verilator --cc ...` 极易出错且效率低。Makefile 可以一键完成编译、链接、运行。
