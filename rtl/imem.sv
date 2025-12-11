// rtl/imem.sv (修正版)
/* verilator lint_off UNUSED */
`define IMEM_DEPTH 256 // 存储 256 个 32 位字

module imem (
    input  logic [31:0] addr_i,     // 输入：PC 地址 (32位)
    output logic [31:0] instr_o     // 输出：指令 (32位)
);

    logic [31:0] imem_arr [`IMEM_DEPTH]; 

    // 初始化存储器 (内容不变)
    initial begin
        imem_arr[0] = 32'h00A02083; // addi x1, x0, 10
        imem_arr[1] = 32'h01402103; // addi x2, x0, 20
        imem_arr[2] = 32'h002081B3; // add x3, x1, x2
        imem_arr[3] = 32'h00000013; // NOP
    end

    // [!!!修正 1 - 解决 WIDTH 警告!!!]
    // 数组索引只需要 8 位，因此我们只取 addr_i[9:2] 作为索引
    // addr_i[9:2] 对应着 IMEM_DEPTH=256 的 1024 字节地址空间
    
    // [!!!修正 2 - 解决 UNUSED 警告!!!]
    // 使用 Verilator 的编译指示来忽略对 addr_i[1:0] 的警告
    
    assign instr_o = imem_arr[addr_i[9:2]]; 
    

endmodule
/* verilator lint_on UNUSED */