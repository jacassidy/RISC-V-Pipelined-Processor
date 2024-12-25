//James Kaden Cassidy jkc.cassidy@gmail.com 12/23/2024

import HighLevelControl::*;

module branchHandler(
    input   pcSrc             PCSrc_C,
    input   conditionalPCSrc  ConditionalPCSrc_C,

    input   logic             Zero,
    input   logic             Carry,
    input   logic             Negative,
    input   logic             oVerflow,

    output  pcSrc             PCSrcPostConditional_C
);

    always_comb begin
        casex (ConditionalPCSrc_C)

            NO_BRANCH:                      PCSrcPostConditional_C = PCSrc_C;
            BEQ_C:  begin
                if(Zero)                    PCSrcPostConditional_C = Branch_C;
                else                        PCSrcPostConditional_C = PCp4_I;
            end
            BNE_C:  begin
                if(~Zero)                   PCSrcPostConditional_C = Branch_C;
                else                        PCSrcPostConditional_C = PCp4_I;
            end
            BLT_C:  begin
                if(Negative ^ oVerflow)     PCSrcPostConditional_C = Branch_C;
                else                        PCSrcPostConditional_C = PCp4_I;
            end
            BGE_C:  begin
                if(~(Negative ^ oVerflow))  PCSrcPostConditional_C = Branch_C;
                else                        PCSrcPostConditional_C = PCp4_I;
            end
            BLTU_C: begin
                if(Carry)                   PCSrcPostConditional_C = Branch_C;
                else                        PCSrcPostConditional_C = PCp4_I;
            end
            BGEU_C: begin
                if(~Carry)                  PCSrcPostConditional_C = Branch_C;
                else                        PCSrcPostConditional_C = PCp4_I;
            end

            default:                        PCSrcPostConditional_C = pcSrc'('x);

        endcase
    end

endmodule