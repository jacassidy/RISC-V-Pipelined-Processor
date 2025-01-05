//James Kaden Cassidy jkc.cassidy@gmail.com 12/23/2024

import HighLevelControl::*;

module branchHandler(
    input   pcSrc             PCSrc_C,
    input   conditionalPCSrc  ConditionalPCSrc_C,

    input   logic             Zero_C,
    input   logic             Carry_C,
    input   logic             Negative_C,
    input   logic             oVerflow_C,

    output  pcSrc             PCSrcPostConditional_C
);

    always_comb begin
        casex (ConditionalPCSrc_C)

            NO_BRANCH:                          PCSrcPostConditional_C = PCSrc_C;
            BEQ_C:  begin
                if(Zero_C)                      PCSrcPostConditional_C = Branch_C;
                else                            PCSrcPostConditional_C = PCp4_I;
            end
            BNE_C:  begin
                if(~Zero_C)                     PCSrcPostConditional_C = Branch_C;
                else                            PCSrcPostConditional_C = PCp4_I;
            end
            BLT_C:  begin
                if(Negative_C ^ oVerflow_C)     PCSrcPostConditional_C = Branch_C;
                else                            PCSrcPostConditional_C = PCp4_I;
            end
            BGE_C:  begin
                if(~(Negative_C ^ oVerflow_C))  PCSrcPostConditional_C = Branch_C;
                else                            PCSrcPostConditional_C = PCp4_I;
            end
            BLTU_C: begin
                if(Carry_C)                     PCSrcPostConditional_C = Branch_C;
                else                            PCSrcPostConditional_C = PCp4_I;
            end
            BGEU_C: begin
                if(~Carry_C)                    PCSrcPostConditional_C = Branch_C;
                else                            PCSrcPostConditional_C = PCp4_I;
            end

            default:                            PCSrcPostConditional_C = pcSrc'('x);

        endcase
    end

endmodule