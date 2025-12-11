// rtl/defines.svh - 全局宏定义

// ALU 操作码定义
`define ALU_ADD     4'b0010 // 加法 (addi, add, lw/sw 地址计算)
`define ALU_SUB     4'b0110 // 减法 (sub, beq/bne 的比较)
`define ALU_AND     4'b0000 // 位与 (and, andi)
`define ALU_OR      4'b0001 // 位或 (or, ori)

// 更多操作码 (如 SLT, SLL, XOR, SRA, etc.) 留待后续添加