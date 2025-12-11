module core_top (
    input  logic        clk,
    input  logic        rst_n,
    output logic [31:0] instr,  // 我们把取出的指令引出来观察
    output logic [31:0] pc      // 把 PC 也引出来观察
);

    // 内部连线
    logic [31:0] pc_wire;

    // 1. 实例化 PC 模块
    pc_reg u_pc_reg (
        .clk       (clk),
        .rst_n     (rst_n),
        .jump_en   (1'b0),    // 暂时先不跳
        .jump_addr (32'b0),
        .pc        (pc_wire)
    );

    // 2. 实例化 IMem 模块
    imem u_imem (
        .raddr (pc_wire),     // PC 的输出 -> Memory 的地址输入
        .rdata (instr)        // Memory 的数据输出 -> 顶层输出
    );

    // 把内部的 pc_wire 连到外部端口方便调试
    assign pc = pc_wire;

endmodule