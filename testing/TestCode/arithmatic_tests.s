.global _start

_start:
    # ADD (x5 = 10 + 20)
    li x1, 10       # Load 10 into x1
    li x2, 20       # Load 20 into x2
    add x5, x1, x2  # x5 = x1 + x2

    # SUB (x6 = 20 - 10)
    li x1, 20       # Load 20 into x1
    li x2, 10       # Load 10 into x2
    sub x6, x1, x2  # x6 = x1 - x2

    # AND (x7 = 0xF0 & 0x0F)
    li x1, 0xF0     # Load 0xF0 into x1
    li x2, 0x0F     # Load 0x0F into x2
    and x7, x1, x2  # x7 = x1 & x2

    # OR (x8 = 0xF0 | 0x0F)
    li x1, 0xF0     # Load 0xF0 into x1
    li x2, 0x0F     # Load 0x0F into x2
    or x8, x1, x2   # x8 = x1 | x2

    # XOR (x9 = 0xAA ^ 0x55)
    li x1, 0xAA     # Load 0xAA into x1
    li x2, 0x55     # Load 0x55 into x2
    xor x9, x1, x2  # x9 = x1 ^ x2

    # SLL (x10 = 0x1 << 4)
    li x1, 0x1      # Load 1 into x1
    li x2, 4        # Load 4 into x2
    sll x10, x1, x2 # x10 = x1 << x2

    # SRL (x11 = 0x10 >> 2)
    li x1, 0x10     # Load 16 (0x10) into x1
    li x2, 2        # Load 2 into x2
    srl x11, x1, x2 # x11 = x1 >> x2

    # SRA (x12 = -16 >> 2)
    li x1, -16      # Load -16 into x1
    li x2, 2        # Load 2 into x2
    sra x12, x1, x2 # x12 = x1 >> x2 (arithmetic)

    # SLT (x13 = 5 < 10)
    li x1, 5        # Load 5 into x1
    li x2, 10       # Load 10 into x2
    slt x13, x1, x2 # x13 = (x1 < x2)

    # SLTU (x14 = 0xFFFFFFFF < 1)
    li x1, -1       # Load -1 (0xFFFFFFFF) into x1
    li x2, 1        # Load 1 into x2
    sltu x14, x1, x2 # x14 = (unsigned x1 < x2)
