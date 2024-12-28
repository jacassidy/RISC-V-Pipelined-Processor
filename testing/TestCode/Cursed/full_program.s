.global _start

_start:
    # LUI: Test loading a constant into the upper 20 bits
    sw x0, 0x4(x0)                                      #1
    lui x2, 0x0            # x2 = 0x0 (edge case)       #2

    # AUIPC: Test PC-relative addressing
    auipc x3, 0x1          # x3 = PC + 0x1000           #3
    auipc x4, 0x0          # x4 = PC (edge case)        #4

    # JAL: Jump and Link
    jal x5, label1         # x5 = PC + 4                    #5
    jal x6, end            # x6 = PC + 4 (branch to end)    $6

label1:
    # JALR: Jump and Link Register
    addi x7, x4, 0x18        # x7 = 12 (address offset)     #7
    jalr x8, 0(x7)         # Jump to PC + 12                #8
    nop                    # Delay slot (should be skipped) #9

    # Branch Instructions
    bne x1, x2, branch_fail # x1 != x2, should not branch   #a
    beq x1, x2, branch_pass # x1 != x2, should branch       #b //WORKING
branch_fail:
    addi x9, x0, 1         # x9 = 1 (should not execute)    #c
branch_pass:

    blt x1, x2, lt_pass    # x2 < x1, should branch             #d
    bge x1, x2, ge_pass    # x1 >= x2, should branch            #e
    bltu x2, x1, ltu_pass  # Unsigned x2 < x1, should branch    #f
    bgeu x1, x2, geu_pass  # Unsigned x1 >= x2, should branch   #10

ge_pass:
    addi x10, x0, 2        # x10 = 2                        #11
lt_pass:
    addi x11, x0, 3        # x11 = 3                        #12
ltu_pass:
    addi x12, x0, 4        # x12 = 4                        #13
geu_pass:
    addi x13, x0, 5        # x13 = 5                        #14

    # Load Instructions
    lw x14, 0x4(x0)          # Load memory (result should be 0) #15
    lb x15, 0x4(x0)          # Test signed byte load            #16
    lbu x16, 0x4(x0)         # Test unsigned byte load          #17

    # Store Instructions
    sw x1, 0x4(x0)           # Store x1 at result               #18
    sh x2, 0x4(x0)           # Store halfword x2 at result      #19
    sb x3, 0x4(x0)           # Store byte x3 at result          #1a

    # Arithmetic and Logic
    add x17, x10, x11      # x17 = x10 + x11 = 5                #1b
    sub x18, x11, x10      # x18 = x11 - x10 = 1                #1c
    xor x19, x10, x12      # x19 = x10 ^ x12                    #1d
    or x20, x11, x13       # x20 = x11 | x13                    #1e
    and x21, x12, x13      # x21 = x12 & x13                    #1f

    sll x22, x10, x11      # x22 = x10 << x11                   #20
    srl x23, x13, x10      # x23 = x13 >> x10                   #21
    sra x24, x13, x11      # x24 = x13 >> x11 (arithmetic)      #22

    # Immediate Arithmetic
    addi x25, x0, -10      # x25 = -10                          #23
    slti x26, x13, 10      # x26 = (x13 < 10) = 1               #24
    sltiu x27, x12, 10     # x27 = (x12 < 10) = 1               #25

    # Logical Immediate
    xori x28, x10, 0xFF    # x28 = x10 ^ 0xFF                   #26
    ori x29, x11, 0x0F     # x29 = x11 | 0x0F                   #27
    andi x30, x12, 0xF0    # x30 = x12 & 0xF0                   #28

end:
    # Final result write
    add x31, x1, x3        # x31 = x1 + x3                      #29
    sw x31, 0xc(x0)         # Store final result in memory (Expected value 0x12346000) #2a
