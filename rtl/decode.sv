// rtl/decode.sv - 指令解码器 (Instruction Decoder)

module decode (
    input  logic [31:0] instr_i,      // 32 位指令机器码
    
    // 输出：寄存器堆的读地址和控制信号
    output logic [4:0]  rs1_addr_o,   // rs1 地址
    output logic [4:0]  rs2_addr_o,   // rs2 地址
    output logic [4:0]  rd_addr_o,    // rd 地址
    
    // 输出：立即数
    output logic [31:0] imm_o,        // 符号扩展后的 32 位立即数
    
    // 【修正：新增 funct7_o 端口】
    output logic [6:0]  opcode_o,     // Opcode
    output logic [2:0]  funct3_o,     // Funct3
    output logic [6:0]  funct7_o      // Funct7 端口 (新增)
);

    // 1. 字段提取 (组合逻辑)
    assign opcode_o = instr_i[6:0];
    assign rd_addr_o  = instr_i[11:7];
    assign funct3_o = instr_i[14:12];
    assign rs1_addr_o = instr_i[19:15];
    assign rs2_addr_o = instr_i[24:20];
    // 【注意：现在 funct7_o 是一个输出端口，可以直接连接指令字段】
    assign funct7_o = instr_i[31:25]; 

    // 2. 立即数生成 (Sign Extension)
    
    // 符号扩展函数 (将 12 位有符号数扩展到 32 位)
    function automatic [31:0] sign_extend_12(input [11:0] data);
        if (data[11]) begin
            sign_extend_12 = { {20{1'b1}}, data }; // 负数，高位补 1
        end else begin
            sign_extend_12 = { {20{1'b0}}, data }; // 正数，高位补 0
        end
    endfunction

    // 暂简化，只生成 I-Type 立即数
    assign imm_o = sign_extend_12(instr_i[31:20]);

endmodule