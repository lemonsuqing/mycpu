// tb/sim_main.cpp (Lab5 最终修正版)

#include <iostream>
#include <verilated.h>
#include "Vcore_top.h" 

Vcore_top* top; 
vluint64_t main_time = 0; 
double sc_time_stamp() { return main_time; }

// 仿真时钟周期函数
void tick(int cycle_count) {
    // 下降沿
    top->clk = 0; main_time++; top->eval();          
    // 上升沿：寄存器和存储器在此刻更新
    top->clk = 1; main_time++; top->eval();          
    
    // 打印 EX/MEM 阶段的关键输出
    printf("Cycle %d: PC=0x%08X, Instr=0x%08X | RS1=0x%08X, RS2=0x%08X | ALU_RES=0x%08X, DM_RD=0x%08X\n", 
           cycle_count, 
           top->pc_out, 
           top->instr_out, 
           top->rs1_data_out,   
           top->rs2_data_out,   
           top->alu_result_out,
           top->dm_rdata_out); // 【新增打印】DM 读取结果
}

int main(int argc, char** argv) {
    
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true); 

    top = new Vcore_top("top"); 

    // 复位并运行 1 周期
    top->rst = 1; top->clk = 0; top->eval(); 
    printf("--- Start Reset ---\n");
    tick(0); 

    top->rst = 0; // 释放复位信号
    printf("--- Reset Released ---\n");

    // 运行 10 周期，观察数据闭环后的结果
    for (int i = 1; i <= 10; ++i) {
        tick(i); 
    }
    printf("--- Simulation Finished ---\n");

    delete top;
    return 0;
}