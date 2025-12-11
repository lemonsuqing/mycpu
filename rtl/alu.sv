// rtl/alu.sv - 算术逻辑单元 (ALU)

`include "defines.svh" 

module alu (
    input  logic [3:0]  alu_op_i,   // ALU 操作码
    input  logic [31:0] src1_i,     // 源操作数 1
    input  logic [31:0] src2_i,     // 源操作数 2
    output logic [31:0] result_o,   // 计算结果
    output logic        zero_o      // 结果为零标志
);

    logic [31:0] alu_result_w; // 内部计算结果

    // 1. ALU 核心计算 (组合逻辑: always_comb)
    always_comb begin
        alu_result_w = 32'd0; // 默认值
        case (alu_op_i)
            `ALU_ADD: alu_result_w = src1_i + src2_i; // 加法
            `ALU_SUB: alu_result_w = src1_i - src2_i; // 减法
            `ALU_AND: alu_result_w = src1_i & src2_i; // 位与
            `ALU_OR:  alu_result_w = src1_i | src2_i; // 位或
            default:  alu_result_w = 32'd0; 
        endcase
    end

    // 2. 结果输出和 Zero 标志
    assign result_o = alu_result_w;
    assign zero_o = (alu_result_w == 32'd0);

endmodule