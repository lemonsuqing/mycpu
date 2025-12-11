// rtl/core_top.sv (Lab4 最终编译通过版)

module core_top (
    input  logic clk,
    input  logic rst,
    output logic [31:0] pc_out,
    output logic [31:0] instr_out,
    output logic [31:0] rs1_data_out,
    output logic [31:0] rs2_data_out,
    output logic [31:0] imm_data_out,
    // 【新增】ALU 结果输出端口
    output logic [31:0] alu_result_out 
);
    
    // --- 内部线网声明 ---
    logic [31:0] pc_next_w; 
    
    // ID 阶段信号
    logic [4:0]  rs1_addr_w, rs2_addr_w, rd_addr_w;
    logic [6:0]  opcode_w;
    logic [2:0]  funct3_w; 
    logic [6:0]  funct7_w; 
    
    // EX 阶段信号
    logic [3:0] alu_op_w;
    logic src2_sel_w;   
    logic [31:0] src2_w;   
    logic alu_zero_w;   // 【警告目标 1：此信号未用】
    
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
    // ... (ID 阶段逻辑不变) ...
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

    // 【修正 1】解决 alu_zero_w UNUSED 警告：使用 lint_off 忽略
    /* verilator lint_off UNUSED */
    logic [0:0] unused_alu_zero;
    assign unused_alu_zero = alu_zero_w;
    /* verilator lint_on UNUSED */
    
endmodule