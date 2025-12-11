# 02\_Lab2\_Instruction\_Fetch.md：RISC-V 处理器核心：IF 阶段与指令存储器

### 1. 实验目标

1. **PC 寄存器：** 实现 PC 寄存器的时序逻辑和自增功能。
2. **指令存储器 (IM)：** 实现 IM 的组合逻辑，用于根据 PC 地址读取指令机器码。
3. **IF 阶段：** 组合 PC 和 IM，完成 RISC-V 五级流水线的**指令提取 (IF)** 阶段。
4. **工具掌握：** 解决 Verilator 的兼容性问题和位宽警告。

### 2. IF 阶段理论：PC 与 IM 的协同工作

IF 阶段是流水线的第一步，目标是从存储器中取出下一条指令。


| 组件        | 功能                                           | 逻辑类型               | 信号关系                                                |
| :---------- | :--------------------------------------------- | :--------------------- | :------------------------------------------------------ |
| **PC 模块** | 存储当前指令地址；时钟上升沿更新；复位时归零。 | 时序逻辑 (`always_ff`) | `pc_out` $\rightarrow$ `pc_next`                        |
| **PC 自增** | 计算下一条指令地址：`PC + 4`。                 | 组合逻辑 (`assign`)    | `pc_out` $\rightarrow$ `pc_next_w`                      |
| **IM 模块** | 根据 PC 地址，即时输出 32 位指令机器码。       | 组合逻辑 (`assign`)    | `pc_out` $\rightarrow$ `addr_i` $\rightarrow$ `instr_o` |

### 3. 项目结构与代码实现

#### 3.1. 项目结构

```
.
├── Makefile
├── build
├── doc
│   └── 02_Lab2_Instruction_Fetch.md  <-- 本手册
├── rtl
│   ├── core_top.sv    # 顶层模块 (连接 PC 和 IM)
│   ├── imem.sv        # 指令存储器模块 (ROM 模拟)
│   └── pc_reg.sv      # PC 寄存器模块 (时序核心)
└── tb
    └── sim_main.cpp   # C++ 仿真驱动程序
```

#### 3.2. RTL 代码

##### A. `rtl/pc_reg.sv` (PC 寄存器)

负责时序存储 PC 值。

```systemverilog
// rtl/pc_reg.sv

module pc_reg (
    input  logic        clk,    
    input  logic        rst,    
    input  logic [31:0] pc_next,  
    output logic [31:0] pc_out  
);
    // 异步复位，同步加载
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out <= 32'h00000000; 
        end 
        else begin
            // 必须使用非阻塞赋值 (<=)
            pc_out <= pc_next;    
        end
    end

endmodule
```

##### B. `rtl/imem.sv` (指令存储器)

负责指令机器码的存储和读取。

```systemverilog
// rtl/imem.sv 
/* verilator lint_off UNUSED */
// 将 lint_off/on 放置在模块内部，确保只影响当前模块
`define IMEM_DEPTH 256 // 存储 256 个 32 位字

module imem (
    input  logic [31:0] addr_i,     // 输入：PC 地址 (32位)
    output logic [31:0] instr_o     // 输出：指令 (32位)
);

    logic [31:0] imem_arr [`IMEM_DEPTH]; 

    // 初始化存储器：预设测试指令 (RISC-V 机器码)
    initial begin
        // addr=0x00: addi x1, x0, 10  (I-Type)
        imem_arr[0] = 32'h00A02093; // 修正：addi x1, x0, 10 机器码为 0x00A02093

        // addr=0x04: addi x2, x0, 20  (I-Type)
        imem_arr[1] = 32'h01402113; // 修正：addi x2, x0, 20 机器码为 0x01402113

        // addr=0x08: add x3, x1, x2  (R-Type)
        imem_arr[2] = 32'h002081B3; // add x3, x1, x2 (正确)
      
        // addr=0x0C: NOP (addi x0, x0, 0)
        imem_arr[3] = 32'h00000013; 
    end

    // 组合逻辑：根据地址读取指令
    // 使用 addr_i[9:2] 作为 8 位索引，解决 WIDTH 警告
    assign instr_o = imem_arr[addr_i[9:2]]; 

endmodule
/* verilator lint_on UNUSED */
```

##### C. `rtl/core_top.sv` (顶层模块)

连接所有子模块，并将关键信号暴露。

```systemverilog
// rtl/core_top.sv 

module core_top (
    input  logic clk,
    input  logic rst,
    output logic [31:0] pc_out,      // PC 寄存器输出
    output logic [31:0] instr_out    // IM 模块输出 (IF 结果)
);
  
    // 内部线网声明
    logic [31:0] pc_next_w; 

    // PC Next 逻辑：PC + 4
    assign pc_next_w = pc_out + 32'd4; 

    // 1. PC 寄存器实例化
    pc_reg u_pc_reg (
        .clk     (clk),
        .rst     (rst),
        .pc_next (pc_next_w),
        .pc_out  (pc_out) 
    );
  
    // 2. 指令存储器实例化
    imem u_imem (
        .addr_i  (pc_out),      // PC 地址
        .instr_o (instr_out)    // 取出的指令
    );

endmodule
```

#### 3.3. Testbench 代码

##### A. `tb/sim_main.cpp`

采用 Verilator 兼容模式，驱动时钟和复位，并打印 PC 和指令。

```cpp
// tb/sim_main.cpp

#include <iostream>
#include <verilated.h>
#include "Vcore_top.h" 

Vcore_top* top; 
// 兼容性修正：使用 vluint64_t 作为仿真时间
vluint64_t main_time = 0; 

// 必须实现 sc_time_stamp
double sc_time_stamp() {
    return main_time;
}

// 仿真时钟周期函数
void tick(int cycle_count) {
    // 下降沿
    top->clk = 0;
    main_time++; 
    top->eval();        

    // 上升沿
    top->clk = 1;
    main_time++; 
    top->eval();        
  
    printf("Cycle %d: PC = 0x%08X | Instruction = 0x%08X\n", 
           cycle_count, top->pc_out, top->instr_out); 
}

int main(int argc, char** argv) {
  
    // 兼容性修正：使用 Verilated 静态方法进行初始化
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true); 

    top = new Vcore_top("top"); 

    // 复位阶段
    top->rst = 1; 
    top->clk = 0;
    top->eval(); 
    printf("--- Start Reset ---\n");
    printf("Initial PC = 0x%08X | Initial Instruction = 0x%08X\n", top->pc_out, top->instr_out);

    tick(0); 

    top->rst = 0; // 释放复位信号
    printf("--- Reset Released ---\n");

    // 运行阶段
    for (int i = 1; i <= 5; ++i) {
        tick(i); 
    }
    printf("--- Simulation Finished ---\n");

    delete top;
    return 0;
}
```

### 4. 踩过的坑与解决


| 问题描述                                | 原因分析                                                                     | 解决方案                                                                                                                        | 涉及文件/代码     |
| :-------------------------------------- | :--------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------ | :---------------- |
| **PC/IM 无法在 C++ 中访问**             | Verilator 默认只暴露模块端口，内部 wire/logic 不可见。                       | 将需要观察的信号 (`pc_out_w`, `instr_w` 等) 提升为 **顶层模块的 `output` 端口**。                                               | `rtl/core_top.sv` |
| **`VerilatedContext` 报错**             | 可能是 Verilator 版本较旧或安装配置问题，不兼容新的 C++ 初始化方式。         | 采用 Verilator 的**静态初始化和时间管理**模式 (`Verilated::commandArgs(...)`, `vluint64_t main_time`, 实现 `sc_time_stamp()`)。 | `tb/sim_main.cpp` |
| **`imem.sv` 位宽警告 (`WIDTH`)**        | 用 30 位 (`addr_i[31:2]`) 索引一个只需 8 位地址 (`imem_arr[255:0]`) 的数组。 | 将数组索引限制为所需的位宽 (`addr_i[9:2]`)。                                                                                    | `rtl/imem.sv`     |
| **`imem.sv` 未使用信号警告 (`UNUSED`)** | PC 地址的最低两位 (`addr_i[1:0]`) 未被使用（因为指令 4 字节对齐）。          | 使用 Verilator 的**编译指示**在代码周围关闭/开启警告 (`/* verilator lint_off UNUSED */`)。                                      | `rtl/imem.sv`     |

### 5. 预期输出


| Cycle |   PC 地址   | Instruction (机器码) |       对应的汇编指令       |
| :---: | :----------: | :------------------: | :-------------------------: |
| **0** | `0x00000000` |     `0x00A02093`     |      `addi x1, x0, 10`      |
| **1** | `0x00000004` |     `0x01402113`     |      `addi x2, x0, 20`      |
| **2** | `0x00000008` |     `0x002081B3`     |      `add x3, x1, x2`      |
| **3** | `0x0000000C` |     `0x00000013`     |            `NOP`            |
| **4** | `0x00000010` |     `0x00000000`     | (RAM未初始化位置，通常为 0) |
| **5** | `0x00000014` |     `0x00000000`     |      (RAM未初始化位置)      |

```
