// rtl/decode.sv - 指令解码器 (Instruction Decoder)

module decode (
    input  logic [31:0] instr_i,      // 输入：32 位指令机器码 (来自 IF 阶段)
    
    // 输出：寄存器堆的读地址和控制信号
    output logic [4:0]  rs1_addr_o,   // rs1 地址
    output logic [4:0]  rs2_addr_o,   // rs2 地址
    output logic [4:0]  rd_addr_o,    // rd 地址 (下一阶段使用)
    
    // 输出：立即数
    output logic [31:0] imm_o,        // 符号扩展后的 32 位立即数
    
    // 【初步】控制信号 (用于下一阶段 EX)
    // 只需要知道 rs1, rs2 读写操作，其他控制信号在 EX 阶段完善
    output logic [6:0]  opcode_o,     // Opcode
    output logic [2:0]  funct3_o      // Funct3
);

    // 1. 字段提取 (组合逻辑)
    assign opcode_o = instr_i[6:0];
    assign rd_addr_o = instr_i[11:7];
    assign funct3_o = instr_i[14:12];
    assign rs1_addr_o = instr_i[19:15];
    assign rs2_addr_o = instr_i[24:20];
    // assign funct7_o = instr_i[31:25]; // 暂不输出 funct7

    // 2. 立即数生成 (Sign Extension)
    // 立即数生成是一个复杂但关键的组合逻辑
    
    // 符号位 (Immediate[31])
    logic sign_bit;
    assign sign_bit = instr_i[31];

    // R-Type / J-Type (jal) / I-Type (addi, lw,...) / S-Type (sw) / B-Type (beq)
    // 我们暂时只处理 **I-Type** 立即数，它是最常见的。
    // I-Type: Imm[11:0] = Instr[31:20]
    
    // 符号扩展函数 (将 12 位有符号数扩展到 32 位)
    function automatic [31:0] sign_extend_12(input [11:0] data);
        if (data[11]) begin
            sign_extend_12 = { {20{1'b1}}, data }; // 负数，高位补 1
        end else begin
            sign_extend_12 = { {20{1'b0}}, data }; // 正数，高位补 0
        end
    endfunction

    // 假设我们只处理 I-Type (Opcode = 7'b0010011 是 ADDI/SLTI 等，Opcode = 7'b0000011 是 LW)
    // 完整的 CPU 需要一个 mux 来选择不同类型的立即数，这里简化为 I-Type
    assign imm_o = sign_extend_12(instr_i[31:20]);

endmodule