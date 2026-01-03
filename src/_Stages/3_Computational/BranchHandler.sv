//James Kaden Cassidy jkc.cassidy@gmail.com 12/23/2024

module branchHandler(
    input   HighLevelControl::pcSrc             PCSrc_C,
    input   HighLevelControl::conditionalPCSrc  ConditionalPCSrc_C,

    input   logic             Zero_C,
    input   logic             Carry_C,
    input   logic             Negative_C,
    input   logic             oVerflow_C,

    output  HighLevelControl::pcSrc             PCSrcPostConditional_C
);

    always_comb begin
        casex (ConditionalPCSrc_C)

            HighLevelControl::NO_BRANCH:        PCSrcPostConditional_C = PCSrc_C;
            HighLevelControl::BEQ_C:  begin
                if(Zero_C)                      PCSrcPostConditional_C = HighLevelControl::Branch_C;
                else                            PCSrcPostConditional_C = HighLevelControl::PCp4_I;
            end
            HighLevelControl::BNE_C:  begin
                if(~Zero_C)                     PCSrcPostConditional_C = HighLevelControl::Branch_C;
                else                            PCSrcPostConditional_C = HighLevelControl::PCp4_I;
            end
            HighLevelControl::BLT_C:  begin
                if(Negative_C ^ oVerflow_C)     PCSrcPostConditional_C = HighLevelControl::Branch_C;
                else                            PCSrcPostConditional_C = HighLevelControl::PCp4_I;
            end
            HighLevelControl::BGE_C:  begin
                if(~(Negative_C ^ oVerflow_C))  PCSrcPostConditional_C = HighLevelControl::Branch_C;
                else                            PCSrcPostConditional_C = HighLevelControl::PCp4_I;
            end
            HighLevelControl::BLTU_C: begin
                if(Carry_C)                     PCSrcPostConditional_C = HighLevelControl::Branch_C;
                else                            PCSrcPostConditional_C = HighLevelControl::PCp4_I;
            end
            HighLevelControl::BGEU_C: begin
                if(~Carry_C)                    PCSrcPostConditional_C = HighLevelControl::Branch_C;
                else                            PCSrcPostConditional_C = HighLevelControl::PCp4_I;
            end

            default:                            PCSrcPostConditional_C = HighLevelControl::pcSrc'('x);

        endcase
    end

endmodule
