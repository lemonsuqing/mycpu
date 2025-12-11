// 注意头文件变了！
#include "Vcore_top.h"
#include "verilated.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    
    // 实例化新的 Top
    Vcore_top* top = new Vcore_top;

    // 跑 10 个周期
    for (int i = 0; i < 10; i++) {
        top->clk = 0;
        top->eval();
        
        top->clk = 1;
        top->eval();

        // 打印 PC 和 当前取到的指令
        printf("Time %d: PC = 0x%08x, Instr = 0x%08x\n", 
               i, top->pc, top->instr);

        // 复位控制
        if (i < 2) top->rst_n = 0;
        else       top->rst_n = 1;
    }

    delete top;
    return 0;
}