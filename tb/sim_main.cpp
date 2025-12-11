// tb/sim_main.cpp (最终兼容修正版)

#include <iostream>
#include <verilated.h>
#include "Vcore_top.h" 

// 顶层模块实例
Vcore_top* top; 

// [!!!修正!!!] 使用 vluint64_t 类型作为仿真时间
vluint64_t main_time = 0; 

// [!!!修正!!!] 定义 timeInc 函数，供 Verilator 内部使用
double sc_time_stamp() {
    return main_time;
}

// 仿真时钟周期函数
// [!!!修正!!!] 移除 contextp 参数
void tick(int cycle_count) {
    // 模拟时钟的交替变化
    top->clk = 0;
    main_time++; // [!!!修正!!!] 增加我们自己的时间计数
    top->eval();          // 评估组合逻辑和时钟下降沿逻辑

    top->clk = 1;
    main_time++; // [!!!修正!!!] 增加我们自己的时间计数
    top->eval();          // 评估时钟上升沿逻辑
    
    // 使用输出端口 pc_out
    printf("Cycle %d: PC = 0x%08X\n", cycle_count, top->pc_out); 
}

int main(int argc, char** argv) {
    // [!!!修正!!!] 采用 Verilator 静态初始化
    // 初始化 Verilator
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true); // 开启追踪 (为下一课做准备)

    // 实例化顶层模块
    top = new Vcore_top("top"); // [!!!修正!!!] 实例化时不再需要传入 contextp

    // 1. 复位阶段 (Reset Phase)
    top->rst = 1; 
    top->clk = 0;
    top->eval(); 
    printf("--- Start Reset ---\n");
    printf("Initial PC = 0x%08X\n", top->pc_out); 

    // 运行一个时钟周期
    tick(0); 

    top->rst = 0; // 释放复位信号
    printf("--- Reset Released ---\n");

    // 2. 运行阶段 (Run Phase)
    for (int i = 1; i <= 5; ++i) {
        tick(i);
    }
    printf("--- Simulation Finished ---\n");

    // 清理
    delete top;
    // [!!!修正!!!] 不再需要 delete contextp
    return 0;
}