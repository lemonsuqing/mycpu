// tb/sim_main.cpp (更新版)

#include <iostream>
#include <verilated.h>
#include "Vcore_top.h" 

Vcore_top* top; 
vluint64_t main_time = 0; 

double sc_time_stamp() {
    return main_time;
}

// 仿真时钟周期函数
void tick(int cycle_count) {
    top->clk = 0;
    main_time++; 
    top->eval();          

    top->clk = 1;
    main_time++; 
    top->eval();          
    
    // 【新增打印】在时钟上升沿后，打印 PC 和取出的指令 (instr_out)
    printf("Cycle %d: PC = 0x%08X | Instruction = 0x%08X\n", 
           cycle_count, top->pc_out, top->instr_out); 
}

int main(int argc, char** argv) {
    
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true); 

    top = new Vcore_top("top"); 

    // 1. 复位阶段 (Reset Phase)
    top->rst = 1; 
    top->clk = 0;
    top->eval(); 
    printf("--- Start Reset ---\n");
    // 打印初始状态
    printf("Initial PC = 0x%08X | Initial Instruction = 0x%08X\n", top->pc_out, top->instr_out);

    tick(0); 

    top->rst = 0; // 释放复位信号
    printf("--- Reset Released ---\n");

    // 2. 运行阶段 (Run Phase)
    for (int i = 1; i <= 5; ++i) {
        tick(i); 
    }
    printf("--- Simulation Finished ---\n");

    delete top;
    return 0;
}