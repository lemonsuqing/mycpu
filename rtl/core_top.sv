module core_top (
    input  logic        clk,
    input  logic        rst_n,
    output logic [31:0] instr,
    output logic [31:0] pc
);

    logic [31:0] pc_wire;

    // PC
    pc_reg u_pc_reg (
        .clk(clk),
        .rst_n(rst_n),
        .jump_en(1'b0),
        .jump_addr(32'b0),
        .pc(pc_wire)
    );

    // IMEM
    imem u_imem (
        .raddr(pc_wire),
        .rdata(instr)
    );

    // 驱动顶层输出端口：必须要写！
    assign pc = pc_wire;

endmodule
