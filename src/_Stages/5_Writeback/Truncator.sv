//James Kaden Cassidy jkc.cassidy@gmail.com 12/21/2024

`include "parameters.svh"

import HighLevelControl::*;

module truncator #(

) (
    input   truncType                   TruncType,
    input   logic[$clog2(`XLEN/8)-1:0]  TruncSrc,
    input   logic[`XLEN-1:0]            InputData,

    output  logic[`XLEN-1:0]            TruncResult
);
    logic misaligned;

    always_comb begin

        case (TruncType)
            HALF_WORD:          misaligned  = TruncSrc[0];      // halfword: bit0 must be 0
            HALF_WORD_UNSIGNED: misaligned  = TruncSrc[0];
            WORD:               misaligned  = |TruncSrc[1:0];   // word: low 2 bits must be 0 (for 32-bit word)
            `ifdef XLEN_64
            WORD_UNSIGNED:      misaligned  = |TruncSrc[1:0];   // dword: low 3 bits must be 0
            `endif
            default :           misaligned = 1'b0;
        endcase

        if (misaligned) begin
            TruncResult = 'x;   // and raise/store-misaligned exception elsewhere
        end else begin
            casex (TruncType)
                BYTE:               TruncResult = {{(`XLEN-8)   {InputData[TruncSrc*8+7]}},     InputData[(TruncSrc<<3)+7  -: 8 ]  };
                HALF_WORD:          TruncResult = {{(`XLEN-16)  {InputData[TruncSrc*8+15]}},    InputData[(TruncSrc<<3)+15 -: 16] };
                WORD:               TruncResult = {{(`XLEN-32)  {InputData[TruncSrc*8+31]}},    InputData[(TruncSrc<<3)+31 -: 32] };

                BYTE_UNSIGNED:      TruncResult = {{(`XLEN-8)   {1'b0}},                        InputData[(TruncSrc<<3)+7  -: 8 ]  };
                HALF_WORD_UNSIGNED: TruncResult = {{(`XLEN-16)  {1'b0}},                        InputData[(TruncSrc<<3)+15 -: 15] };

                `ifdef XLEN_64
                    WORD_UNSIGNED:  TruncResult = {{(`XLEN-32)  {1'b0}},                        InputData[(TruncSrc<<3)+31 -: 32] };
                `endif

                NO_TRUNC:           TruncResult = InputData;
                default:            TruncResult = 'x;
            endcase
        end
    end

endmodule
