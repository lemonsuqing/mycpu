// rtl/imem.sv - 指令存储器 (Instruction Memory)

/* verilator lint_off UNUSED */
`define IMEM_DEPTH 256 // 存储 256 个 32 位字

module imem (
    input  logic [31:0] addr_i,     // 输入：PC 地址 (32位)
    output logic [31:0] instr_o     // 输出：指令 (32位)
);

    logic [31:0] imem_arr [`IMEM_DEPTH]; 

    // 初始化存储器：使用正确的 ADDI 和 ADD 机器码
    initial begin
        // addr=0x00: addi x1, x0, 10  (Opcode: 7'b0010011)
        imem_arr[0] = 32'h00A02093; 

        // addr=0x04: addi x2, x0, 20  (Opcode: 7'b0010011)
        imem_arr[1] = 32'h01402113;

        // addr=0x08: add x3, x1, x2  (Opcode: 7'b0110011)
        imem_arr[2] = 32'h002081B3; 
        
        // addr=0x0C: NOP (addi x0, x0, 0)
        imem_arr[3] = 32'h00000013; 
    end
    
    // 组合逻辑：根据地址读取指令
    assign instr_o = imem_arr[addr_i[9:2]]; 
    

endmodule
/* verilator lint_on UNUSED */