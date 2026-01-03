//James Kaden Cassidy jkc.cassidy@gmail.com 4/19/25

`ifndef FMA_PARAMETERS
`define FMA_PARAMETERS

`define DEBUG

typedef enum logic[5:0] {
        NoSpecialCase,
        ZeroTimesInf,
        InputsNaN,
        CalculatedNaN,
        MultiplicationOverflow,
        AdditionOverflow
} specialCase;

`endif
