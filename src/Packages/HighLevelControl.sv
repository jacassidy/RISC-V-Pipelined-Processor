//James Kaden Cassidy jkc.cassidy@gmail.com 12/20/2024

package HighLevelControl
    typedef enum logic[3:0] {
        ADD,
        SUB,
        OR,
        AND,
        XOR,

        SLL,
        SLT,
        SLTU,
        SRL,
        SRA,
        
        NONE,
    } aluOperation;

    typedef enum logic[2:0] {
        Imm11t0,
        Imm4t0,
        SType,
        UType,
        NONE,
    } immSrc;

    typedef enum logic {
        Rs1     = 1'b0, 
        OldPC   = 1'b1
    } aluSrcA;

    typedef enum logic {  
        Rs2     = 1'b0,
        Imm     = 1'b1,
    } aluSrcB;

    typedef enum logic[1:0] {
        ALU,
        Memory,
        Rs2
    } resultSrc;

    typedef enum logic[2:0] {
        BYTE,
        HALF_WORD,
        WORD,
        BYTE_UNSIGNED,
        HALF_WORD_UNSIGNED,
        NONE
    } truncSrc;

endpackage