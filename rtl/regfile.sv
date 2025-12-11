// rtl/regfile.sv - 寄存器堆 (Register File)

module regfile (
    input  logic        clk,          // 时钟
    input  logic        rst,          // 复位

    // 读取端口 (组合逻辑)
    input  logic [4:0]  rs1_addr_i,   // rs1 寄存器地址
    input  logic [4:0]  rs2_addr_i,   // rs2 寄存器地址
    output logic [31:0] rs1_data_o,   // rs1 寄存器数据
    output logic [31:0] rs2_data_o,   // rs2 寄存器数据
    
    // 写入端口 (时序逻辑)
    input  logic        we_i,         // 写使能 (Write Enable)
    input  logic [4:0]  rd_addr_i,    // 目标寄存器地址 (rd)
    input  logic [31:0] rd_data_i     // 写入的数据
);

    // 存储 32 个 32 位的寄存器
    // 寄存器地址是 5 位 (2^5=32)
    logic [31:0] registers [31:0]; 

    // 1. 读取操作 (Read) - 组合逻辑
    // rs1_data_o = (rs1_addr_i == 5'd0) ? 32'd0 : registers[rs1_addr_i];
    // rs2_data_o = (rs2_addr_i == 5'd0) ? 32'd0 : registers[rs2_addr_i];

    // RISC-V 规定 x0 恒为 0
    // SystemVerilog 的 '?' 运算符
    assign rs1_data_o = (rs1_addr_i == 5'd0) ? 32'd0 : registers[rs1_addr_i];
    assign rs2_data_o = (rs2_addr_i == 5'd0) ? 32'd0 : registers[rs2_addr_i];

    // 2. 写入操作 (Write) - 时序逻辑
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // 复位时初始化所有寄存器（可选，Verilator/FPGA 通常默认初始化）
            // for (int i=0; i<32; i++) registers[i] <= 32'd0;
        end
        // 只有写使能 (we_i) 为高，且目标地址 (rd_addr_i) 不是 x0 (5'd0) 时才写入
        else if (we_i && rd_addr_i != 5'd0) begin
            registers[rd_addr_i] <= rd_data_i;
        end
    end

    // 3. 方便仿真调试，我们在初始时给寄存器 x1, x2, x3 赋初值
    initial begin
        registers[1] = 32'h00000000;
        registers[2] = 32'h00000000;
        registers[3] = 32'h00000000;
        // 确保 x0 恒为 0
        registers[0] = 32'd0; 
    end

endmodule