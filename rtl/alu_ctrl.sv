// rtl/alu_ctrl.sv - ALU 控制单元 (ALU Control Unit)

`include "defines.svh" 

module alu_ctrl (
    input  logic [6:0]  opcode_i,   // Opcode 
    input  logic [2:0]  funct3_i,   // Funct3 
    // 【警告目标 2：funct7_i 部分位未用】
    /* verilator lint_off UNUSED */
    input  logic [6:0]  funct7_i,   // Funct7 
    /* verilator lint_on UNUSED */
    
    output logic [3:0]  alu_op_o    // ALU 操作码 
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
                3'b000: alu_op_o = `ALU_ADD; // addi
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