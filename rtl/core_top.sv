// rtl/core_top.sv (更新版)

module core_top (
    input  logic clk,
    input  logic rst,
    output logic [31:0] pc_out,
    // 【新增】将取出的指令也暴露给顶层，方便 Testbench 观察 IF 阶段的结果
    output logic [31:0] instr_out 
);
    
    // 内部线网声明
    logic [31:0] pc_next_w; 

    // 1. PC 寄存器实例化
    // 组合逻辑：PC 自增 4
    assign pc_next_w = pc_out + 32'd4; 

    pc_reg u_pc_reg (
        .clk     (clk),
        .rst     (rst),
        .pc_next (pc_next_w),
        .pc_out  (pc_out) 
    );
    
    // 2. 指令存储器实例化
    imem u_imem (
        .addr_i  (pc_out),      // PC 的输出作为 IM 的地址输入
        .instr_o (instr_out)    // IM 的输出作为指令输出
    );

endmodule