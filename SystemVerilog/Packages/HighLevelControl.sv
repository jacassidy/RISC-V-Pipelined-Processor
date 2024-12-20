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

    typedef enum logic[1:0] {
        
        
        NONE,
    } immExtender;

endpackage