//James Kaden Cassidy jkc.cassidy@gmail.com 12/21/2024

import HighLevelControl::*;

`define WORD_SIZE 32

module immediateExtender #(
    BIT_COUNT
) (
    input   immSrc                  ImmSrc,
    input   logic[`WORD_SIZE-1:0]   Instr,
    
    output  logic[BIT_COUNT-1:0]    Imm
);

    logic[4:0]      Immb4t0, shamt;
    logic[11:5]     Immb11t5;
    logic[11:0]     Immb11t0;
    logic[31:12]    Immb31t12;
    logic[10:1]     Immb10t1;
    logic[19:12]    Immb19t12;
    logic[10:5]     Immb10t5;
    logic[4:1]      Immb4t1;

    assign Immb11t0 = Instr[31:20];

    assign shamt = Instr[24:20];

    //Stype
    assign Immb4t0      = Instr[11:7];
    assign Immb11t5     = Instr[31:25];

    //Utype
    assign Immb31t12    = Instr[31:12];

    //JType
    assign Immb10t1     = Instr[30:21];
    assign Immb19t12    = Instr[19:12];

    //BType
    assign Immb10t5     = Instr[30:25];
    assign Immb4t1      = Instr[11:8];
    always_comb begin
        casex (ImmSrc)
            Imm11t0:    Imm = {{(BIT_COUNT-12){Instr[31]}}, Immb11t0 };
            Imm4t0:     Imm = {{(BIT_COUNT-5) {1'bx     }}, shamt    }; //Shift immediate, only 5 bits needed
            SType:      Imm = {{(BIT_COUNT-12){Instr[31]}}, Immb11t5, Immb4t0 };
            UType:      Imm = {{(BIT_COUNT-32){Instr[31]}}, Immb31t12, 12'b0};
            JType:      Imm = {{(BIT_COUNT-31){Instr[31]}}, Instr[31], Immb19t12, Instr[20], Immb10t1, 1'b0};
            BType:      Imm = {{(BIT_COUNT-13){Instr[31]}}, Instr[31], Instr[7], Immb10t5, Immb4t1, 1'b0};

            default: Imm = 'x;
        endcase
    end
    
endmodule