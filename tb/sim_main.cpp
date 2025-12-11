// tb/sim_main.cpp
#include "Vpc_reg.h"  // Verilator 会自动把 pc_reg.sv 编译成这个 C++ 头文件
#include "verilated.h"

int main(int argc, char** argv) {
    // 1. 初始化 Verilator 上下文
    Verilated::commandArgs(argc, argv);
    
    // 2. 实例化你的模块 (在 C++ 里，它就是一个对象)
    Vpc_reg* top = new Vpc_reg;

    // 3. 模拟运行
    // 让我们跑 10 个时钟周期
    for (int i = 0; i < 10; i++) {
        // --- 模拟前半个周期 (时钟低电平) ---
        top->clk = 0;
        top->eval(); // 计算电路状态

        // --- 模拟后半个周期 (时钟高电平，上升沿来了！) ---
        top->clk = 1;
        top->eval(); // 电路状态更新 (pc <= next_pc 在这里发生)

        // 打印当前的 PC 值
        printf("Time %d: PC = 0x%08x\n", i, top->pc);

        // --- 控制信号逻辑 ---
        
        // 前两个周期我们要复位，否则 PC 值是随机的垃圾
        if (i < 2) {
            top->rst_n = 0; // 低电平复位
        } else {
            top->rst_n = 1; // 释放复位
        }

        // 在第 5 个周期，我们要尝试跳转！
        if (i == 5) {
            top->jump_en = 1;       // 开启跳转
            top->jump_addr = 0x1234; // 目标地址
            printf("  [Jump Signal] -> 0x1234\n");
        } else {
            top->jump_en = 0;       // 关闭跳转
        }
    }

    // 4. 清理内存
    delete top;
    return 0;
}