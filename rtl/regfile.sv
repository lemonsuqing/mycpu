module regfile (
    input  logic        clk,
    
    // 读端口 1 (Source 1)
    input  logic [4:0]  raddr1,
    output logic [31:0] rdata1,

    // 读端口 2 (Source 2)
    input  logic [4:0]  raddr2,
    output logic [31:0] rdata2,

    // 写端口 (Destination)
    input  logic        we,      // Write Enable (写使能，1表示要写)
    input  logic [4:0]  waddr,   // 写给谁 (x0-x31)
    input  logic [31:0] wdata    // 写什么数据
);

    // 定义 32 个 32位的寄存器
    logic [31:0] regs [0:31];

    // --- 读逻辑 (组合逻辑) ---
    // 只要地址给过来，数据马上送出去 (类似 SRAM 的异步读，或者纯逻辑连线)
    // 这里的坑：读 x0 的时候必须强制返回 0，哪怕 regs[0] 里存了垃圾
    assign rdata1 = (raddr1 == 5'b0) ? 32'b0 : regs[raddr1];
    assign rdata2 = (raddr2 == 5'b0) ? 32'b0 : regs[raddr2];

    // --- 写逻辑 (时序逻辑) ---
    always_ff @(posedge clk) begin
        // 只有当 we=1 且 写入地址不是 0 时，才允许修改
        if (we && waddr != 5'b0) begin
            regs[waddr] <= wdata;
        end
    end

endmodule