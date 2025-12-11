// rtl/pc_reg.sv

// 使用 SystemVerilog 的 'logic' 类型，它是 'wire' 和 'reg' 的综合体
module pc_reg (
    input  logic        clk,      // 时钟信号
    input  logic        rst,      // 复位信号 (这里我们使用高电平有效，即 rst=1 时复位)
    input  logic [31:0] pc_next,  // 下一个 PC 值 (32位)
    output logic [31:0] pc_out    // 当前 PC 值 (32位)
);

    // always_ff 宏指示 Verilator/综合工具这是一个时序逻辑块 (FF: Flip-Flop)
    // 敏感列表：监测时钟上升沿 (posedge clk) 或复位上升沿 (posedge rst)
    always_ff @(posedge clk or posedge rst) begin
        // 异步复位 (Asynchronous Reset): 复位信号一变高，立即执行复位
        if (rst) begin
            pc_out <= 32'h00000000; // 复位时，PC 归零
        end 
        // 同步加载 (Synchronous Load): 只有在时钟上升沿时才更新
        else begin
            // **非阻塞赋值 (<=)**：这是时序逻辑中必须使用的赋值方式。
            // 它模拟了数据在时钟到来时才并行更新到寄存器的行为。
            pc_out <= pc_next;      
        end
    end

endmodule