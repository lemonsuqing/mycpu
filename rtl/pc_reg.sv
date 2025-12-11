module pc_reg (
    input  logic        clk,
    input  logic        rst_n,
    
    // 新增跳转控制信号
    input  logic        jump_en,    // 1表示要跳转
    input  logic [31:0] jump_addr,  // 跳转的目标地址

    output logic [31:0] pc
);

    logic [31:0] next_pc;

    // 组合逻辑：计算 next_pc
    always_comb begin
        if (jump_en) begin
            // 如果跳转使能有效，下一条就是目标地址
            next_pc = jump_addr;
        end else begin
            // 否则正常顺序执行
            next_pc = pc + 4;
        end
    end

    // 时序逻辑：更新 PC
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'h0;
        end else begin
            pc <= next_pc;
        end
    end

endmodule