# 03\_Lab3\_Instruction\_Decode.md：RISC-V 处理器核心：指令解码（ID 阶段）

### 1. 实验目标

1. **寄存器堆 (Register File)：** 实现 32 个 RISC-V 通用寄存器的存储和读取逻辑。
2. **指令解码：** 实现指令字段的提取和立即数生成。
3. **数据路径连接：** 连接 IF 阶段的指令输出到解码器和寄存器堆。

### 2. ID 阶段理论：寄存器堆与指令解析

#### A. 寄存器堆 (Register File)

寄存器堆存储 32 个 32 位的通用寄存器 ($x0$ 到 $x31$)。它具有以下特性：

* **双端口读取：** 根据 `rs1` 和 `rs2` 地址（来自指令），组合逻辑地输出两个操作数。
* **单端口写入：** 只有在时钟上升沿且写使能 (`RegWrite`) 有效时，才将数据写入 `rd` 指定的寄存器。
* **$x0$ 零寄存器：** $x0$ 永远返回 $0$，且对 $x0$ 的写入操作被忽略。

#### B. 指令格式与立即数生成 (以 I-Type 为例)

ID 阶段的主要任务就是将 32 位指令机器码解析为控制信号和数据。


| 字段           | 位宽 | 指令位    | 功能            |
| :------------- | :--- | :-------- | :-------------- |
| **Opcode**     | 7    | `[6:0]`   | 主操作码        |
| **rd**         | 5    | `[11:7]`  | 目标寄存器地址  |
| **rs1**        | 5    | `[19:15]` | 源寄存器 1 地址 |
| **rs2**        | 5    | `[24:20]` | 源寄存器 2 地址 |
| **funct3**     | 3    | `[14:12]` | 辅助操作码      |
| **I-Type Imm** | 12   | `[31:20]` | 立即数          |

### 3. 项目结构与代码实现

#### 3.1. 需新增和修改的文件


| 文件              | 状态     | 功能描述                         |
| :---------------- | :------- | :------------------------------- |
| `rtl/regfile.sv`  | **新增** | 实现寄存器堆的时序逻辑。         |
| `rtl/decode.sv`   | **新增** | 实现指令字段提取和立即数生成。   |
| `rtl/core_top.sv` | **修改** | 集成`regfile` 和 `decode` 模块。 |
| `tb/sim_main.cpp` | **修改** | 增加对 ID 阶段输出的观察。       |

#### 3.2. RTL 文件：`rtl/regfile.sv` (寄存器堆模块)

```systemverilog
// rtl/regfile.sv - 寄存器堆 (Register File)

module regfile (
    input  logic        clk,      
    input  logic        rst,      

    // 读取端口 (组合逻辑)
    input  logic [4:0]  rs1_addr_i,   // rs1 寄存器地址
    input  logic [4:0]  rs2_addr_i,   // rs2 寄存器地址
    output logic [31:0] rs1_data_o,   // rs1 寄存器数据
    output logic [31:0] rs2_data_o,   // rs2 寄存器数据
  
    // 写入端口 (时序逻辑)
    input  logic        we_i,         // 写使能
    input  logic [4:0]  rd_addr_i,    // 目标寄存器地址 (rd)
    input  logic [31:0] rd_data_i     // 写入的数据
);

    logic [31:0] registers [31:0]; 

    // 1. 读取操作 (Read) - 组合逻辑：x0 恒为 0
    assign rs1_data_o = (rs1_addr_i == 5'd0) ? 32'd0 : registers[rs1_addr_i];
    assign rs2_data_o = (rs2_addr_i == 5'd0) ? 32'd0 : registers[rs2_addr_i];

    // 2. 写入操作 (Write) - 时序逻辑：只有 we_i=1 且 rd_addr_i != x0 才写入
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // 可以在此处添加初始化所有寄存器为 0 的代码
        end
        else if (we_i && rd_addr_i != 5'd0) begin
            // 必须使用非阻塞赋值 (<=)
            registers[rd_addr_i] <= rd_data_i;
        end
    end

    // 3. 初始赋值 (用于调试，避免寄存器被 Verilator 设为 X)
    initial begin
        // 初始化所有寄存器为 0
        for (int i=0; i<32; i++) registers[i] = 32'd0;
    end

endmodule
```

#### 3.3. RTL 文件：`rtl/decode.sv` (指令解码模块)

```systemverilog
// rtl/decode.sv - 指令解码器 (Instruction Decoder)

module decode (
    input  logic [31:0] instr_i,      // 32 位指令机器码
  
    // 输出：寄存器堆的读地址和控制信号
    output logic [4:0]  rs1_addr_o,   // rs1 地址
    output logic [4:0]  rs2_addr_o,   // rs2 地址
    output logic [4:0]  rd_addr_o,    // rd 地址 (下一阶段使用)
  
    // 输出：立即数
    output logic [31:0] imm_o,        // 符号扩展后的 32 位立即数
  
    // 【初步】控制信号 
    output logic [6:0]  opcode_o,     // Opcode
    output logic [2:0]  funct3_o,     // Funct3
    output logic [6:0]  funct7_o      // Funct7 (新增)
);

    // 1. 字段提取 (组合逻辑)
    assign opcode_o = instr_i[6:0];
    assign rd_addr_o  = instr_i[11:7];
    assign funct3_o = instr_i[14:12];
    assign rs1_addr_o = instr_i[19:15];
    assign rs2_addr_o = instr_i[24:20];
    assign funct7_o = instr_i[31:25]; // Funct7

    // 2. 立即数生成 (Sign Extension) - I-Type 立即数
  
    // 符号扩展函数 (将 12 位有符号数扩展到 32 位)
    function automatic [31:0] sign_extend_12(input [11:0] data);
        if (data[11]) begin
            sign_extend_12 = { {20{1'b1}}, data }; // 负数，高位补 1
        end else begin
            sign_extend_12 = { {20{1'b0}}, data }; // 正数，高位补 0
        end
    endfunction

    // 暂简化，只生成 I-Type 立即数 (用于 ADDI, LW 等)
    assign imm_o = sign_extend_12(instr_i[31:20]);

endmodule
```

#### 3.4. RTL 文件：`rtl/core_top.sv` (修正和更新)

这个版本已修正所有语法错误和重复代码。

```systemverilog
// rtl/core_top.sv (ID 阶段最终修正版)

module core_top (
    input  logic clk,
    input  logic rst,
    output logic [31:0] pc_out,
    output logic [31:0] instr_out,
    // 【新增】ID 阶段暴露的输出
    output logic [31:0] rs1_data_out,
    output logic [31:0] rs2_data_out,
    output logic [31:0] imm_data_out
);
  
    // --- 内部线网声明 ---
    logic [31:0] pc_next_w; 
  
    // ID 阶段输出的地址/控制信号
    logic [4:0]  rs1_addr_w, rs2_addr_w, rd_addr_w;
    logic [6:0]  opcode_w;
    logic [2:0]  funct3_w; // 新增 Funct3
    logic [6:0]  funct7_w; // 新增 Funct7
  
    // 寄存器堆的写使能和写入数据 (暂设为 0)
    logic we_w;      
    logic [31:0] wb_data_w; 

    // --- 1. IF 阶段 (指令提取) ---
    assign pc_next_w = pc_out + 32'd4; 

    pc_reg u_pc_reg (
        .clk     (clk), .rst     (rst),
        .pc_next (pc_next_w), .pc_out  (pc_out) 
    );
  
    imem u_imem (
        .addr_i  (pc_out), 
        .instr_o (instr_out)
    );

    // --- 2. ID 阶段 (指令解码) ---
  
    // 指令解码器
    decode u_decode (
        .instr_i    (instr_out),
        .rs1_addr_o (rs1_addr_w),
        .rs2_addr_o (rs2_addr_w),
        .rd_addr_o  (rd_addr_w),
        .imm_o      (imm_data_out), // 连接到顶层输出
        .opcode_o   (opcode_w),
        .funct3_o   (funct3_w),     // 【连接】Funct3
        .funct7_o   (funct7_w)      // 【连接】Funct7
    );
  
    // 寄存器堆
    assign we_w = 1'b0; 
    assign wb_data_w = 32'd0;

    regfile u_regfile (
        .clk        (clk),
        .rst        (rst),
        .rs1_addr_i (rs1_addr_w),
        .rs2_addr_i (rs2_addr_w),
        .rs1_data_o (rs1_data_out), // 连接到顶层输出
        .rs2_data_o (rs2_data_out), // 连接到顶层输出
        .we_i       (we_w),
        .rd_addr_i  (rd_addr_w),
        .rd_data_i  (wb_data_w)
    );

endmodule
```

#### 3.5. Testbench 文件：`tb/sim_main.cpp` (更新)

增加对 ID 阶段输出的打印。

```cpp
// tb/sim_main.cpp (ID 阶段更新版)

#include <iostream>
#include <verilated.h>
#include "Vcore_top.h" 

Vcore_top* top; 
vluint64_t main_time = 0; 
double sc_time_stamp() { return main_time; }

// 仿真时钟周期函数
void tick(int cycle_count) {
    // 下降沿
    top->clk = 0; main_time++; top->eval();      
    // 上升沿
    top->clk = 1; main_time++; top->eval();      
  
    // 【更新打印】增加 RS1 Data, RS2 Data, 立即数
    printf("Cycle %d: PC=0x%08X, Instr=0x%08X | RS1=0x%08X, RS2=0x%08X, IMM=0x%08X\n", 
           cycle_count, 
           top->pc_out, 
           top->instr_out, 
           top->rs1_data_out,   
           top->rs2_data_out,   
           top->imm_data_out);  
}

int main(int argc, char** argv) {
    // ... (初始化代码不变) ...
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true); 
    top = new Vcore_top("top"); 

    // 复位并运行 1 周期
    top->rst = 1; top->clk = 0; top->eval(); 
    printf("--- Start Reset ---\n");
    tick(0); 

    top->rst = 0; 
    printf("--- Reset Released ---\n");

    // 运行 5 周期
    for (int i = 1; i <= 5; ++i) {
        tick(i); 
    }
    printf("--- Simulation Finished ---\n");

    delete top;
    return 0;
}
```

### 4. 实验验证

在项目根目录执行 `make clean`，然后执行 `make`。

#### 预期输出验证：

观察 `RS1` 和 `IMM` 字段是否正确提取（由于寄存器尚未写入，`RS1`/`RS2` 初始为 $0$）：


| Cycle |   PC   | Instruction | RS1 Data | RS2 Data |   IMM Data   |                      验证点                      |
| :---: | :----: | :----------: | :------: | :------: | :----------: | :----------------------------------------------: |
| **0** | `0x00` | `0x00A02093` |  `0x00`  |  `0x00`  | `0x0000000A` |      `addi x1, x0, 10` $\rightarrow$ Imm=10      |
| **1** | `0x04` | `0x01402113` |  `0x00`  |  `0x00`  | `0x00000014` |      `addi x2, x0, 20` $\rightarrow$ Imm=20      |
| **2** | `0x08` | `0x002081B3` |  `0x00`  |  `0x00`  | `0x00000000` | `add x3, x1, x2` $\rightarrow$ Imm (I-Type) 为 0 |

---

### 5. 踩过的坑与解决


| 问题描述                     | 原因分析                                                | 解决方案                                                                    | 涉及文件/代码     |
| :--------------------------- | :------------------------------------------------------ | :-------------------------------------------------------------------------- | :---------------- |
| **`core_top.sv` 端口语法错** | 端口声明间忘记用逗号`,` 分隔，导致 Verilator 识别错误。 | 确保所有端口声明之间都用`,` 分隔，最后一个端口后跟 `)`。                    | `rtl/core_top.sv` |
| **`core_top.sv` 代码重复**   | `IF 阶段` 逻辑被复制粘贴了两次，导致多重定义。          | 删除重复的`assign` 和模块实例化代码，只保留一份。                           | `rtl/core_top.sv` |
| **`regfile.sv` 写入问题**    | 写入$x0$ 寄存器会被忽略的特性必须在硬件中实现。         | 在`regfile` 的 `always_ff` 块中添加条件：`if (we_i && rd_addr_i != 5'd0)`。 | `rtl/regfile.sv`  |
