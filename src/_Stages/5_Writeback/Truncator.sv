//James Kaden Cassidy jkc.cassidy@gmail.com 12/21/2024

`define WORD_SIZE 32

module truncator #(
    BIT_COUNT
) (
    input HighLevelControl::truncSrc TruncSrc,
    input logic[BIT_COUNT-1:0] Input,

    output logic[BIT_COUNT-1:0] TruncResult
);
    import HighLevelControl::truncSrc::*;

    casex (TruncSrc)
        BYTE:               TruncResult = {(BIT_COUNT-32-16-8)  * InputWord[7],             InputWord[7:0]};
        HALF_WORD:          TruncResult = {(BIT_COUNT-32-16)    * InputWord[15],            InputWord[15:0]};
        BYTE_UNSIGNED:      TruncResult = {(BIT_COUNT-32-16-8)  * 1'b0,                     InputWord[7:0]};
        HALF_WORD_UNSIGNED: TruncResult = {(BIT_COUNT-32-16)    * 1'b0,                     InputWord[15:0]};
        WORD:               TruncResult = InputWord;

        NONE: TruncResult = InputWord;
        default: TruncResult = 'x;
    endcase
    
endmodule