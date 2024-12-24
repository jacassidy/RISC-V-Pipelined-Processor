//James Kaden Cassidy jkc.cassidy@gmail.com 12/23/2024

module branchHandler(
    input   HighLevelControl::pcSrc             PCSrc_C,
    input   HighLevelControl::conditionalPCSrc  ConditionalPCSrc_C,

    input   logic                               Zero,
    input   logic                               Carry,
    input   logic                               Negative,
    input   logic                               oVerflow,

    output  HighLevelControl::pcSrc             PCSrcPostConditional_C
);

    always_comb begin
        casex(ConditionalPCSrc_C)

            NONE:                           PCSrcPostConditional_C = PCSrc_C;
            BEQ_C:  begin
                if(Zero)                    PCSrcPostConditional_C = Branch_C;
                else                        PCSrcPostConditional_C = PCp4;
            end
            BNE_C:  begin
                if(~Zero)                   PCSrcPostConditional_C = Branch_C;
                else                        PCSrcPostConditional_C = PCp4;
            end
            BLT_C:  begin
                if(Negative ^ oVerflow)     PCSrcPostConditional_C = Branch_C;
                else                        PCSrcPostConditional_C = PCp4;
            end
            BGE_C:  begin
                if(~(Negative ^ oVerflow))  PCSrcPostConditional_C = Branch_C;
                else                        PCSrcPostConditional_C = PCp4;
            end
            BLTU_C: begin
                if(Carry)                   PCSrcPostConditional_C = Branch_C;
                else                        PCSrcPostConditional_C = PCp4;
            end
            BGEU_C: begin
                if(~Carry)                  PCSrcPostConditional_C = Branch_C;
                else                        PCSrcPostConditional_C = PCp4;
            end

            default                         PCSrcPostConditional_C = 'x: 

        endcase
    end

endmodule