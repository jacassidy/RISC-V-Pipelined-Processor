.global _start

# Define start of the program
_start:
    # Test ADD
    li x1, 5             # Load 5 into x1
    li x2, 10            # Load 10 into x2
    add x3, x1, x2       # x3 = x1 + x2 (5 + 10)

    # Test SUB
    sub x4, x2, x1       # x4 = x2 - x1 (10 - 5)

    # Test AND
    li x5, 0xF0          # Load 0xF0 into x5
    li x6, 0x0F          # Load 0x0F into x6
    and x7, x5, x6       # x7 = x5 & x6 (0xF0 & 0x0F)

    # Test OR
    or x8, x5, x6        # x8 = x5 | x6 (0xF0 | 0x0F)

    # Test XOR
    xor x9, x5, x6       # x9 = x5 ^ x6 (0xF0 ^ 0x0F)

    # Test SLL
    li x10, 1            # Load 1 into x10
    li x11, 4            # Load 4 into x11
    sll x12, x10, x11    # x12 = x10 << x11 (1 << 4)

    # Test SRL
    li x13, 0x10         # Load 16 (0x10) into x13
    srl x14, x13, x11    # x14 = x13 >> x11 (16 >> 4)

    # Test SRA
    li x15, -16          # Load -16 into x15
    sra x16, x15, x11    # x16 = x15 >> x11 (arithmetic)

    # Test SLT
    slt x17, x1, x2      # x17 = (x1 < x2) (5 < 10)

    # Test SLTU
    li x18, -1           # Load -1 (0xFFFFFFFF) into x18
    li x19, 1            # Load 1 into x19
    sltu x20, x18, x19   # x20 = (unsigned x18 < x19)

    # Test ADDI
    addi x21, x0, 42     # x21 = x0 + 42 (42)

    # Test Function Call
    jal x1, func         # Jump and link to function
    li x30, 0xDEAD       # Placeholder for testing return
    j end                # Jump to end

func:
    li x22, 123          # Load 123 into x22
    ret                  # Return from function

end:
    # Test LUI
    lui x23, 0x12345     # Load upper immediate 0x12345000 into x23

    # Test AUIPC
    auipc x24, x1       # Load PC-relative address into x24
