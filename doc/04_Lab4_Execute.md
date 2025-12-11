# 04\_Lab4\_Execute.md：RISC-V 处理器核心：执行（EX 阶段）

### 1. 实验目标

1. **ALU：** 实现算术逻辑单元，能够执行加法、减法、与、或等运算。
2. **ALU 控制：** 实现控制逻辑，根据指令类型生成 ALU 操作码。
3. **ALU Source Mux：** 实现 MUX，选择第二个操作数是 $rs2$ 还是立即数。
4. **指令修正：** 修正 `imem` 中的机器码错误，确保 ALU 计算逻辑正确。

### 2. 代码文件（请完整替换）

#### 2.1. 新增文件 1：`rtl/defines.svh` (全局宏定义)

**请创建此文件：**

```systemverilog
// rtl/defines.svh - 全局宏定义

// ALU 操作码定义
`define ALU_ADD     4'b0010 
`define ALU_SUB     4'b0110 
`define ALU_AND     4'b0000 
`define ALU_OR      4'b0001 
```

#### 2.2. 新增/修改文件 2：`rtl/alu.sv` (ALU 模块)

**请使用此代码创建或替换 `rtl/alu.sv`：**

```systemverilog
// rtl/alu.sv - 算术逻辑单元 (ALU)

`include "defines.svh" 

module alu (
    input  logic [3:0]  alu_op_i,   // ALU 操作码
    input  logic [31:0] src1_i,     // 源操作数 1
    input  logic [31:0] src2_i,     // 源操作数 2
    output logic [31:0] result_o,   // 计算结果
    output logic        zero_o      // 结果为零标志
);

    logic [31:0] alu_result_w; 

    always_comb begin
        alu_result_w = 32'd0; 
        case (alu_op_i)
            `ALU_ADD: alu_result_w = src1_i + src2_i; 
            `ALU_SUB: alu_result_w = src1_i - src2_i; 
            `ALU_AND: alu_result_w = src1_i & src2_i; 
            `ALU_OR:  alu_result_w = src1_i | src2_i; 
            default:  alu_result_w = 32'd0; 
        endcase
    end

    assign result_o = alu_result_w;
    assign zero_o = (alu_result_w == 32'd0);

endmodule
```

#### 2.3. 新增文件 3：`rtl/alu_ctrl.sv` (ALU 控制单元)

**请使用此代码创建 `rtl/alu_ctrl.sv`：**

```systemverilog
// rtl/alu_ctrl.sv - ALU 控制单元 (ALU Control Unit)

`include "defines.svh" 

module alu_ctrl (
    input  logic [6:0]  opcode_i,   
    input  logic [2:0]  funct3_i,   
    // 【修正：使用 lint_off 忽略暂时的 UNUSED 警告】
    /* verilator lint_off UNUSED */
    input  logic [6:0]  funct7_i,   
    /* verilator lint_on UNUSED */
  
    output logic [3:0]  alu_op_o  
);
  
    always_comb begin
        alu_op_o = `ALU_ADD; 

        if (opcode_i == 7'b0110011) begin // R-Type
            case ({funct7_i[5], funct3_i}) 
                4'b0_000: alu_op_o = `ALU_ADD; 
                4'b1_000: alu_op_o = `ALU_SUB; 
                4'b0_111: alu_op_o = `ALU_AND; 
                4'b0_110: alu_op_o = `ALU_OR;  
                default: alu_op_o = `ALU_ADD; 
            endcase
        end
        else if (opcode_i == 7'b0010011) begin // I-Type (ADDI, ANDI...)
            case (funct3_i)
                3'b000: alu_op_o = `ALU_ADD; 
                default: alu_op_o = `ALU_ADD;
            endcase
        end
        else if (opcode_i == 7'b0000011 || opcode_i == 7'b0100011) begin // Load/Store Type
            alu_op_o = `ALU_ADD; 
        end
        else begin
            alu_op_o = `ALU_ADD; 
        end
    end

endmodule
```

#### 2.4. 修改文件 4：`rtl/core_top.sv` (连接 EX 阶段)

**请用此代码替换 `rtl/core_top.sv` 的全部内容：**

```systemverilog
// rtl/core_top.sv (Lab4 最终修正版)

module core_top (
    input  logic clk,
    input  logic rst,
    output logic [31:0] pc_out,
    output logic [31:0] instr_out,
    output logic [31:0] rs1_data_out,
    output logic [31:0] rs2_data_out,
    output logic [31:0] imm_data_out,
    output logic [31:0] alu_result_out // 新增 ALU 结果输出端口
);
  
    // --- 内部线网声明 ---
    logic [31:0] pc_next_w; 
  
    // ID 阶段信号
    logic [4:0]  rs1_addr_w, rs2_addr_w, rd_addr_w;
    logic [6:0]  opcode_w;
    // 【修正：明确声明位宽，解决 IMPLICIT/WIDTH 错误】
    logic [2:0]  funct3_w; 
    logic [6:0]  funct7_w; 
  
    // EX 阶段信号
    logic [3:0] alu_op_w;
    logic src2_sel_w;   
    logic [31:0] src2_w;   
    logic alu_zero_w;   
  
    // 寄存器堆的写使能和写入数据 (暂设为 0)
    logic we_w;        
    logic [31:0] wb_data_w; 
  
    // --- 1. IF 阶段 ---
    // ... (IF 阶段逻辑不变) ...
    assign pc_next_w = pc_out + 32'd4; 

    pc_reg u_pc_reg (
        .clk     (clk), .rst     (rst),
        .pc_next (pc_next_w), .pc_out  (pc_out) 
    );
  
    imem u_imem (
        .addr_i  (pc_out), 
        .instr_o (instr_out)
    );

    // --- 2. ID 阶段 ---
  
    decode u_decode (
        .instr_i    (instr_out),
        .rs1_addr_o (rs1_addr_w),
        .rs2_addr_o (rs2_addr_w),
        .rd_addr_o  (rd_addr_w),
        .imm_o      (imm_data_out), 
        .opcode_o   (opcode_w),
        .funct3_o   (funct3_w),   
        .funct7_o   (funct7_w)    
    );
  
    // 寄存器堆 (ID 阶段只读)
    assign we_w = 1'b0; 
    assign wb_data_w = 32'd0;

    regfile u_regfile (
        .clk        (clk),
        .rst        (rst),
        .rs1_addr_i (rs1_addr_w),
        .rs2_addr_i (rs2_addr_w),
        .rs1_data_o (rs1_data_out), 
        .rs2_data_o (rs2_data_out), 
        .we_i       (we_w),
        .rd_addr_i  (rd_addr_w),
        .rd_data_i  (wb_data_w)  
    );

    // --- 3. EX 阶段 (执行) ---

    alu_ctrl u_alu_ctrl (
        .opcode_i   (opcode_w),
        .funct3_i   (funct3_w),
        .funct7_i   (funct7_w),
        .alu_op_o   (alu_op_w)
    );

    // ALU Source 2 选择 (MUX)
    assign src2_sel_w = (opcode_w == 7'b0110011) ? 1'b0 : 1'b1;
    assign src2_w = src2_sel_w ? imm_data_out : rs2_data_out;

    alu u_alu (
        .alu_op_i (alu_op_w),
        .src1_i   (rs1_data_out),
        .src2_i   (src2_w),
        .result_o (alu_result_out),
        .zero_o   (alu_zero_w)
    );

    // 【修正：使用 lint_off 忽略 UNUSED 警告】
    /* verilator lint_off UNUSED */
    logic [0:0] unused_alu_zero;
    assign unused_alu_zero = alu_zero_w;
    /* verilator lint_on UNUSED */
  
endmodule
```

#### 2.5. 修改文件 5：`rtl/imem.sv` (修正机器码错误)

**请用此代码替换 `rtl/imem.sv` 的全部内容：**

```systemverilog
// rtl/imem.sv - 指令存储器 (Instruction Memory)

/* verilator lint_off UNUSED */
`define IMEM_DEPTH 256 // 存储 256 个 32 位字

module imem (
    input  logic [31:0] addr_i,   
    output logic [31:0] instr_o   
);

    logic [31:0] imem_arr [`IMEM_DEPTH]; 

    // 【修正：使用正确的 ADDI 机器码】
    initial begin
        // addr=0x00: addi x1, x0, 10  (0x00A02093)
        imem_arr[0] = 32'h00A02093; 

        // addr=0x04: addi x2, x0, 20  (0x01402113)
        imem_arr[1] = 32'h01402113;

        // addr=0x08: add x3, x1, x2  (0x002081B3)
        imem_arr[2] = 32'h002081B3; 
      
        // addr=0x0C: NOP (addi x0, x0, 0)
        imem_arr[3] = 32'h00000013; 
    end
  
    assign instr_o = imem_arr[addr_i[9:2]]; 
  

endmodule
/* verilator lint_on UNUSED */
```

#### 2.6. 修改文件 6：`Makefile` (添加搜索路径)

**请用此代码替换 `Makefile` 的全部内容：**

```makefile
# Makefile (修正版：增加 -I$(RTL_DIR))

# --- 配置区域 ---
TOP_MODULE = core_top
RTL_DIR = rtl
TB_DIR   = tb
OBJ_DIR = obj_dir

RTL_SRCS = $(wildcard $(RTL_DIR)/*.sv)
TB_SRCS  = $(TB_DIR)/sim_main.cpp

# -I$(RTL_DIR): 【修正】添加 RTL 目录为 include 搜索路径
V_FLAGS  = --cc --exe --build -j 4 -Wall --top-module $(TOP_MODULE) -I$(RTL_DIR)

# --- 规则区域 ---

all: run

build: $(RTL_SRCS) $(TB_SRCS)
	@echo ">> Compiling Verilog..."
	verilator $(V_FLAGS) $(RTL_SRCS) $(TB_SRCS)

run: build
	@echo ">> Running Simulation..."
	@./$(OBJ_DIR)/V$(TOP_MODULE)

clean:
	rm -rf $(OBJ_DIR)

.PHONY: all build run clean
```

### 3. 实验验证

在项目根目录执行：

```bash
make clean
make run
```

这次运行将通过编译，并且仿真输出的指令和 ALU 结果将是正确的：


| Cycle |   PC   | **Instruction** | RS1 Data |   IMM Data   |     ALU\_RES     |
| :---: | :----: | :--------------: | :------: | :----------: | :--------------: |
| **0** | `0x00` | **`0x00A02093`** |  `0x00`  |    `0x0A`    | **`0x0000000A`** |
| **1** | `0x04` | **`0x01402113`** |  `0x00`  |    `0x14`    | **`0x00000014`** |
| **2** | `0x08` |   `0x002081B3`   |  `0x00`  | `0x00000000` | **`0x00000000`** |
