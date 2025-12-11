// rtl/core_top.sv (最终修正版)

module core_top (
    input  logic clk,
    input  logic rst,
    output logic [31:0] pc_out,
    output logic [31:0] instr_out,
    // 【修正 1】端口列表用逗号分隔
    output logic [31:0] rs1_data_out,
    output logic [31:0] rs2_data_out,
    output logic [31:0] imm_data_out
); // 模块定义结束括号

    // --- 内部线网声明 ---
    logic [31:0] pc_next_w; 
    logic [4:0]  rs1_addr_w, rs2_addr_w, rd_addr_w;
    logic [6:0]  opcode_w;
    logic we_w;          // 寄存器写使能
    logic [31:0] wb_data_w; // 寄存器写数据

    // --- 1. IF 阶段 (指令提取) ---
    // 【修正 2】只保留一次逻辑
    
    // PC Next 逻辑：PC + 4
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
        .imm_o      (imm_data_out),
        .opcode_o   (opcode_w),
        .funct3_o   ()               // 暂不使用
    );
    
    // 寄存器堆
    // 暂时的假定写操作：写使能为 0，写数据为 0 (ID 阶段只读)
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

endmodule