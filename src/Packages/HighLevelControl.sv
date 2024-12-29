//James Kaden Cassidy jkc.cassidy@gmail.com 12/20/2024

`include "parameters.svh"

package HighLevelControl;

    typedef enum logic[1:0] {
        PCp4_I,
        Jump_R,      //PCpImm
        Jump_C,      //AluAdd
        Branch_C     //UpdatedPC
    } pcSrc;

    typedef enum logic[2:0] {
        NO_BRANCH,
        BEQ_C,       //UpdatedPC
        BNE_C,
        BLT_C,
        BGE_C,
        BLTU_C,
        BGEU_C
    } conditionalPCSrc;

    typedef enum logic[2:0] {
        Imm11t0,
        Imm4t0,
        SType,
        UType,
        JType,
        BType
    } immSrc;

    typedef enum logic {
        PCpImm,
        PCp4
    } updatedPCSrc;

    // typedef enum logic {
    //     Rs1     = 1'b0, 
    //     OldPC   = 1'b1
    // } aluSrcA;

    typedef enum logic {  
        Rs2     = 1'b0,
        Imm     = 1'b1
    } aluSrcB;

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
        SRA
    } aluOperation;

    //Could feed all data out of ALU and combine with this mux
    typedef enum logic[1:0] {
        ALU,
        ALUOpB,
        UpdatedPC
    } computeSrc;

    typedef enum logic {
        Compute,
        Memory
    } resultSrc;

    typedef enum logic[2:0] {
        BYTE,
        HALF_WORD,
        WORD,
        BYTE_UNSIGNED,
        HALF_WORD_UNSIGNED,

        `ifdef BIT_COUNT_64
            WORD_UNSIGNED,
        `endif

        NO_TRUNC
    } truncSrc;

endpackage