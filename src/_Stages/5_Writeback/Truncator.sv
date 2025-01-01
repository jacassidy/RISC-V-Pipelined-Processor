//James Kaden Cassidy jkc.cassidy@gmail.com 12/21/2024

`include "parameters.svh"

import HighLevelControl::*;

module truncator #(

) (
    input   truncSrc                TruncSrc,
    input   logic[`BIT_COUNT-1:0]    Input,

    output  logic[`BIT_COUNT-1:0]    TruncResult
);

    always_comb begin
        casex (TruncSrc)
            BYTE:               TruncResult = {{(`BIT_COUNT-8)   {Input[7]}},   Input[7:0]  };
            HALF_WORD:          TruncResult = {{(`BIT_COUNT-16)  {Input[15]}},  Input[15:0] };
            WORD:               TruncResult = {{(`BIT_COUNT-32)  {Input[31]}},  Input[31:0] };
            
            BYTE_UNSIGNED:      TruncResult = {{(`BIT_COUNT-8)   {1'b0}},       Input[7:0]  };
            HALF_WORD_UNSIGNED: TruncResult = {{(`BIT_COUNT-16)  {1'b0}},       Input[15:0] };

            `ifdef BIT_COUNT_64
                WORD_UNSIGNED:  TruncResult = {{(`BIT_COUNT-32)  {1'b0}},       Input[31:0] };
            `endif

            NO_TRUNC:           TruncResult = Input;
            default:            TruncResult = truncSrc'('x);
        endcase
    end
    
endmodule