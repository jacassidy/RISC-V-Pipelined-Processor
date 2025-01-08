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
        IType,
        Shamt,
        SType,
        UType,
        JType,
        BType
    } immSrc;

    typedef enum logic[1:0] {
        PCpImm,
        PCp4,
        WriteData,
        LoadImm
    } passthroughSrc;

    typedef enum logic {  
        Rs2     = 1'b0,
        Imm     = 1'b1
    } aluSrcB;

    typedef enum logic[3:0] { //make sure 0 operation cant turn operands 0 and 0 into anything else
        ADD,
        SUB,
        OR,
        AND,
        XOR,
        SLT,
        SLTU,

        `ifdef BIT_COUNT_64
            ADDW,
            SUBW,
            SLLW,
            SRLW,
            SRAW,
        `endif

        SLL,
        SRL,
        SRA


    } aluOperation;

    //Could feed all data out of ALU and combine with this mux
    typedef enum logic {
        ALU,
        Passthrough
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

    `ifdef PIPELINED

        typedef enum logic[1:0] {
            Rs1_NO_FORWARD,
            Rs1_ComputeResult,
            Rs1_Rd1W,
            Rs1_Rd1PostW
        } rs1ForwardSrc;

        typedef enum logic[1:0] {
            Rs2_NO_FORWARD,
            Rs2_ComputeResult,
            Rs2_Rd1W,
            Rs2_Rd1PostW
        } rs2ForwardSrc;

    `endif

endpackage