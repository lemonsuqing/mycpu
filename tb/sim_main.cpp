#include "Vcore_top.h"
#include "verilated.h"
#include <cstdio>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vcore_top* top = new Vcore_top;

    // ---- 加复位 ----
    top->clk = 0;
    top->rst_n = 0;
    top->eval();

    // 几个周期的复位
    for (int i = 0; i < 5; i++) {
        top->clk = 0; top->eval();
        top->clk = 1; top->eval();
    }

    // 释放复位
    top->rst_n = 1;

    // ---- 正常运行 ----
    for (int i = 0; i < 10; i++) {
        top->clk = 0; top->eval();
        top->clk = 1; top->eval();

        printf("Time %d: PC=0x%08x Instr=0x%08x\n",
            i, top->pc, top->instr);
    }

    delete top;
    return 0;
}
