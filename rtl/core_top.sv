// rtl/core_top.sv (Lab5 最终修正版)

module core_top (
    input  logic clk,
    input  logic rst,
    output logic [31:0] pc_out,
    output logic [31:0] instr_out,
    output logic [31:0] rs1_data_out,
    output logic [31:0] rs2_data_out,
    output logic [31:0] imm_data_out,
    output logic [31:0] alu_result_out,
    // 【新增】DM 读取数据，方便调试
    output logic [31:0] dm_rdata_out 
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
    logic alu_zero_w;   

    // 【新增】MEM/WB 阶段控制信号和数据
    logic reg_write_w;      // 寄存器写使能 (RegWrite)
    logic mem_read_w;       // 数据存储器读使能 (MemRead)
    logic mem_write_w;      // 数据存储器写使能 (MemWrite)
    logic wb_data_sel_w;    // 写回数据选择 (0: ALU 结果; 1: DM 读取数据)
    logic [31:0] wb_data_w; // 最终写回寄存器的数据
    
    // --- 1. IF 阶段 ---
    // ... (PC, IM 逻辑不变) ...
    assign pc_next_w = pc_out + 32'd4; 

    pc_reg u_pc_reg ( .clk(clk), .rst(rst), .pc_next(pc_next_w), .pc_out(pc_out) );
    imem u_imem ( .addr_i(pc_out), .instr_o(instr_out) );

    // --- 2. ID 阶段 ---
    
    decode u_decode (
        .instr_i(instr_out), .rs1_addr_o(rs1_addr_w), .rs2_addr_o(rs2_addr_w), 
        .rd_addr_o(rd_addr_w), .imm_o(imm_data_out), .opcode_o(opcode_w),
        .funct3_o(funct3_w), .funct7_o(funct7_w)      
    );
    
    // 2.1 主控制单元 (Main Control Unit) - 组合逻辑
    always_comb begin
        // 默认值：不读/写内存，不写寄存器，写回数据选 ALU 结果
        reg_write_w   = 1'b0;
        mem_read_w    = 1'b0;
        mem_write_w   = 1'b0;
        wb_data_sel_w = 1'b0; // 0: ALU Result

        case (opcode_w)
            7'b0110011: begin // R-Type: ADD/SUB/AND/OR...
                reg_write_w   = 1'b1; 
            end
            7'b0010011: begin // I-Type (ADDI, ANDI...)
                reg_write_w   = 1'b1; 
            end
            7'b0000011: begin // Load Type (LW, LH...): LW = 7'b0000011 + Funct3=3'b010
                reg_write_w   = 1'b1; 
                mem_read_w    = 1'b1; 
                wb_data_sel_w = 1'b1; // 写回 DM 读取结果
            end
            7'b0100011: begin // Store Type (SW, SH...): SW = 7'b0100011 + Funct3=3'b010
                mem_write_w   = 1'b1; 
            end
            default: begin 
            end
        endcase
    end


    // 2.2 寄存器堆 (Register File)
    regfile u_regfile (
        .clk(clk), .rst(rst),
        .rs1_addr_i(rs1_addr_w), .rs2_addr_i(rs2_addr_w),
        .rs1_data_o(rs1_data_out), .rs2_data_o(rs2_data_out),
        .we_i(reg_write_w), .rd_addr_i(rd_addr_w), .rd_data_i(wb_data_w) // 【连接】WB Data
    );
    
    // --- 3. EX 阶段 ---

    alu_ctrl u_alu_ctrl (
        .opcode_i(opcode_w), .funct3_i(funct3_w), .funct7_i(funct7_w), .alu_op_o(alu_op_w)
    );

    // ALU Source 2 选择 (MUX)
    assign src2_sel_w = (opcode_w == 7'b0110011) ? 1'b0 : 1'b1;
    assign src2_w = src2_sel_w ? imm_data_out : rs2_data_out;

    alu u_alu (
        .alu_op_i(alu_op_w), .src1_i(rs1_data_out), .src2_i(src2_w), 
        .result_o(alu_result_out), .zero_o(alu_zero_w)
    );

    // 【修正】忽略 alu_zero_w UNUSED 警告
    /* verilator lint_off UNUSED */
    logic [0:0] unused_alu_zero;
    assign unused_alu_zero = alu_zero_w;
    /* verilator lint_on UNUSED */
    
    // --- 4. MEM 阶段 ---
    
    dmem u_dmem (
        .clk(clk), .rst(rst),
        .addr_i(alu_result_out), // ALU 结果作为 DM 地址
        .wdata_i(rs2_data_out),  // Store 指令写入 rs2 数据
        .mem_read_i(mem_read_w),
        .mem_write_i(mem_write_w),
        .rdata_o(dm_rdata_out)   // 【连接】DM 读取数据到顶层输出
    );

    // --- 5. WB 阶段 (写回) ---
    // 写回数据 MUX (wb_data_sel_w)
    // 0: ALU Result (alu_result_out)
    // 1: DM Read Data (dm_rdata_out)
    assign wb_data_w = wb_data_sel_w ? dm_rdata_out : alu_result_out;

endmodule