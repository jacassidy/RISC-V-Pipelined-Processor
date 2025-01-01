.globl _start

_start:
    lui x1, 0xFFFFF    # 1) lui x1, <imm>
    addi x1, x1, -529  # 2) addi x1, x1, imm
    sw x1, 0(x0)       # 3) sw rs2, offset(rs1)
    sh x1, 4(x0)       # 4) sh rs2, offset(rs1)
    sb x1, 8(x0)       # 5) sb rs2, offset(rs1)
    lw x4, 0(x0)       # 6) lw x1, offset(rs1)
    lhu x1, 0(x0)      # 7) lh x1, offset(rs1)
    lbu x1, 0(x0)      # 8) lb x1, offset(rs1)
    lh x1, 0(x0)       # 9) lh x1, offset(rs1)
    lb x1, 0(x0)       # 10) lb x1, offset(rs1)
    auipc x1, 0xFEEDF  # 11) auipc x1, <imm>
    sltiu x1, x1, 10   # 12) sltiu x1, x1, imm
    slti x2, x1, 10    # 13) slti x1, x1, imm
    xori x1, x2, 0x55  # 14) xori x1, x1, rs2
    ori x1, x1, 0xAA   # 15) ori x1, x1, rs2
    andi x1, x1, 0xFF  # 16) andi x1, x1, imm
    add x1, x1, x1     # 17) add x1, x1, x1
    sub x0, x1, x1     # 18) sub x1, x1, x1
    sll x6, x4, x2     # 19) sll x1, x1, x1
    srl x1, x4, x2     # 20) srl x1, x1, x1
    sra x7, x4, x2     # 21) sra x1, x1, x1
    slt x2, x7, x0     # 22) slt x1, x1, x0
    sltu x0, x7, x0    # 23) sltu x1, x1, x0
    xor x5, x6, x7     # 24) xor x1, x1, x1
    or x5, x6, x7      # 25) or x1, x1, x1
    and x31, x6, x7    # 26) and x1, x1, x1
    fence              # 27) fence
    slli x1, x4, 31    # 28) slli x1, x1, imm
    srli x1, x4, 31    # 29) srli x1, x1, imm
    srai x1, x4, 16    # 30) srai x1, x1, imm
    nop                # 31) nop
