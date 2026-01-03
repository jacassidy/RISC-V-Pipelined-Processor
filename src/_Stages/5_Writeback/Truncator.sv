//James Kaden Cassidy jkc.cassidy@gmail.com 12/21/2024

`include "parameters.svh"

module truncator #(

) (
    input   HighLevelControl::truncType TruncType,
    input   logic[$clog2(`XLEN/8)-1:0]  TruncSrc,
    input   logic[`XLEN-1:0]            InputData,

    output  logic[`XLEN-1:0]            TruncResult
);
    logic misaligned;

    always_comb begin

        case (TruncType)
            HighLevelControl::HALF_WORD:          misaligned  = TruncSrc[0];      // halfword: bit0 must be 0
            HighLevelControl::HALF_WORD_UNSIGNED: misaligned  = TruncSrc[0];
            HighLevelControl::WORD:               misaligned  = |TruncSrc[1:0];   // word: low 2 bits must be 0 (for 32-bit word)
            `ifdef XLEN_64
            HighLevelControl::WORD_UNSIGNED:      misaligned  = |TruncSrc[1:0];   // dword: low 3 bits must be 0
            `endif
            default :           misaligned = 1'b0;
        endcase

        if (misaligned) begin
            TruncResult = 'x;   // and raise/store-misaligned exception elsewhere
        end else begin
            casex (TruncType)
                HighLevelControl::BYTE:               TruncResult = {{(`XLEN-8)   {InputData[(TruncSrc*8)+7]}},  InputData[(TruncSrc*8)+7  -: 8 ] };
                HighLevelControl::HALF_WORD:          TruncResult = {{(`XLEN-16)  {InputData[(TruncSrc*8)+15]}}, InputData[(TruncSrc*8)+15 -: 16] };
                HighLevelControl::WORD:               TruncResult = {{(`XLEN-32)  {InputData[(TruncSrc*8)+31]}}, InputData[(TruncSrc*8)+31 -: 32] };

                HighLevelControl::BYTE_UNSIGNED:      TruncResult = {{(`XLEN-8)   {1'b0}},                        InputData[(TruncSrc*8)+7  -: 8 ] };
                HighLevelControl::HALF_WORD_UNSIGNED: TruncResult = {{(`XLEN-16)  {1'b0}},                        InputData[(TruncSrc*8)+15 -: 16] };

                `ifdef XLEN_64
                HighLevelControl::WORD_UNSIGNED:  TruncResult = {{(`XLEN-32)  {1'b0}},                        InputData[(TruncSrc*8)+31 -: 32] };
                `endif

                HighLevelControl::NO_TRUNC:           TruncResult = InputData;
                default:            TruncResult = 'x;
            endcase
        end
    end

endmodule
