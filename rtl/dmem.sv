// rtl/dmem.sv - 数据存储器 (Data Memory)

`define DMEM_DEPTH 1024 // 存储 1024 个 32 位字 (4K 字节)

module dmem (
    // 【警告目标 1：addr_i[1:0] 未使用】
    /* verilator lint_off UNUSED */
    input  logic [31:0] addr_i,       // 地址 (来自 ALU 结果)
    /* verilator lint_on UNUSED */
    input  logic        clk,          // 时钟
    input  logic        rst,          // 复位
    
    input  logic [31:0] wdata_i,      // 写入数据 (来自 rs2)
    
    // 【警告目标 2：mem_read_i 未使用】
    /* verilator lint_off UNUSED */
    input  logic        mem_read_i,   // 读使能 (MemRead)
    /* verilator lint_on UNUSED */
    input  logic        mem_write_i,  // 写使能 (MemWrite)
    
    output logic [31:0] rdata_o       // 读取数据
);

    logic [31:0] dmem_arr [`DMEM_DEPTH]; 
    
    // 1. 读取操作 (Read) - 组合逻辑
    // 【修正 1】：使用 addr_i[11:2] 作为 10 位索引，解决 WIDTH 警告
    assign rdata_o = dmem_arr[addr_i[11:2]]; 

    // 2. 写入操作 (Write) - 时序逻辑
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // 复位逻辑（可选）
        end
        else if (mem_write_i) begin
            // 【修正 1】：使用 addr_i[11:2]
            dmem_arr[addr_i[11:2]] <= wdata_i;
        end
    end
    
    // 3. 初始化
    initial begin
        dmem_arr[0] = 32'hdeadbeef; 
    end

endmodule