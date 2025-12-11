/* verilator lint_off UNUSED */
module imem (
    input  logic [31:0] raddr, // 读地址 (来自于 PC)
    output logic [31:0] rdata  // 读数据 (输出指令机器码)
);

    // 1. 定义内存
    // logic [位宽] 名字 [深度];
    // 这里定义一个存了 16 个 32位数字的数组
    logic [31:0] RAM [0:15];

    // 2. 初始化指令 (模拟烧录固件)
    initial begin
        // 下标是字索引 (Word Index)
        RAM[0] = 32'h00000013; // addr=0:  nop (addi x0, x0, 0)
        RAM[1] = 32'h00100093; // addr=4:  addi x1, x0, 1   (x1 = 1)
        RAM[2] = 32'h00208133; // addr=8:  add  x2, x1, x0  (x2 = x1 + x0)
        RAM[3] = 32'hdeadbeef; // addr=12: 结束标志 (我们自己定的)
    end

    // 3. 读逻辑 (组合逻辑)
    // 只要地址变了，数据立刻变
    // raddr[5:2] 等价于 (raddr / 4) % 16
    // 为什么取 [5:2]？
    // - 忽略低2位 ([1:0]) 因为是对齐的
    // - 只取到第5位，因为我们深度只有16 (2^4)，防止数组越界
    assign rdata = RAM[raddr[5:2]];
  

endmodule
/* verilator lint_on UNUSED */