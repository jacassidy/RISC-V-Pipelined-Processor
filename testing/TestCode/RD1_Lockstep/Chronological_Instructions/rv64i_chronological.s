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
    addi x1, x1, 1     
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
    slli x16, x4, 31    # 28) slli x1, x1, imm
    srli x19, x4, 31    # 29) srli x1, x1, imm
    srai x1, x4, 16    # 30) srai x1, x1, imm
    nop                # 31) nop

    #do larger shifts
    slli x1, x16, 36    # 32) slli x1, x1, imm
    srli x2, x16, 36    # 33) srli x1, x1, imm
    srai x1, x16, 36    # 34) srai x1, x1, imm

    #setup for w tests
    slli x3, x2, 36
    or   x5, x2, x3

    #32 Bit instructions
    addiw x1, x5, 0x7FF         #FFFFF6F00FFFFF6F 
    subw  x1, x5, x1            #FFFFF6F00FFFFF6F - 000000001000076E
    slliw x1, x5, 16
    srliw x1, x5, 16
    sraiw x1, x5, 16
    sraiw x1, x19, 4

    sd  x5, 0xc(x0)
    ld  x1, 0xc(x0)
    lwu x1, 0(x0)

    addi x2, x1, 1
    addi x1, x1, 1

    # addw
    # sllw
    # srlw
    # sraw

