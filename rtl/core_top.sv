// rtl/core_top.sv (修正后)

module core_top (
    input  logic clk,
    input  logic rst,
    output logic [31:0] pc_out 
);
    
    // 内部线网声明
    logic [31:0] pc_next_w; 

    // 组合逻辑：简单的自增，模拟 CPU 顺序执行指令
    // RISC-V 指令是 4 字节，所以 PC 每次递增 4
    // assign 是组合逻辑，使用阻塞赋值 (=) 或直接 assign
    assign pc_next_w = pc_out + 32'd4; 

    // 实例化 pc_reg 模块
    // 命名惯例： u_ + 模块名
    pc_reg u_pc_reg (
        .clk     (clk),
        .rst     (rst),
        .pc_next (pc_next_w),
        .pc_out  (pc_out) 
    );

    // 为了在 Testbench 中方便查看 PC 值，我们通过 Verilator 的机制访问内部信号。
    // 在真实设计中，通常不会在顶层做额外的输出。
    // 在 C++ Testbench 中，我们可以通过 `top->u_pc_reg->pc_out` 访问。

endmodule