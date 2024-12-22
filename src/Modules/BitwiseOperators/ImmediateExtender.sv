//James Kaden Cassidy jkc.cassidy@gmail.com 12/21/2024

`define WORD_SIZE 32

module immediateExtender #(
    BIT_COUNT
) (
    input HighLevelControl::immSrc ImmSrc,
    input logic[WORD_SIZE-1:0] Instr,
    
    output logic[BIT_COUNT-1:0] Imm
);
    import HighLevelControl::immSrc::*;

    logic[4:0] Immb4t0, shamt;
    logic[11:0] Immb11t0;
    logic[11:5] Immb11t5;

    assign Immb11t0 = Instr[31:20];

    assign shamt = Instr[24:20];

    assign Immb4t0 = Instr[11:7];
    assign Immb11t5 = Instr[31:25];

    casex (ImmSrc)
        Imm11t0:    Imm = {(BIT_COUNT-12) * Instr[31], Immb11t0 };
        Imm4t0:     Imm = {(BIT_COUNT-5)  * 1'bx     , shamt    }; //Shift immediate, only 5 bits needed
        SType:      Imm = {(BIT_COUNT-12) * Instr[31], Immb11t5, Immb4t0 };

        default: Imm = 'x;
    endcase
    
endmodule