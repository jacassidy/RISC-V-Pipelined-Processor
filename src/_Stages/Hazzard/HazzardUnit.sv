//James Kaden Cassidy jkc.cassidy@gmail.com 1/5/2025

`include "parameters.svh"

`ifdef PIPELINED
module hazzardUnit(
    input   logic                               clk,
    input   logic                               reset,

    input   logic[$clog2(`WORD_SIZE)-1:0]       rs1Adr_R,
    input   logic[$clog2(`WORD_SIZE)-1:0]       rs2Adr_R,

    input   logic[$clog2(`WORD_SIZE)-1:0]       rd1Adr_C,
    input   logic[$clog2(`WORD_SIZE)-1:0]       rd1Adr_M,

    input   logic                               MemEn_C,
    input   logic                               MemWriteEn_C,
    input   logic                               RegWrite_C,
    input   logic                               RegWrite_M,

    output  HighLevelControl::rs1ForwardSrc     Rs1ForwardSrc_C,
    output  HighLevelControl::rs2ForwardSrc     Rs2ForwardSrc_C,

    output  logic                               StallPC,
    output  logic                               StallIR,
    output  logic                               FlushRC
);

    HighLevelControl::rs1ForwardSrc     Rs1ForwardSrcNext;
    HighLevelControl::rs2ForwardSrc     Rs2ForwardSrcNext;

    //Forwarding signals need to be delayed one clock cycle due to forwarding being determined in R stage of next instruction
    always_ff @(posedge clk) begin

        if(reset) begin
            Rs1ForwardSrc_C     <= HighLevelControl::Rs1_NO_FORWARD;
            Rs2ForwardSrc_C     <= HighLevelControl::Rs2_NO_FORWARD;
        end else begin
            Rs1ForwardSrc_C     <= Rs1ForwardSrcNext;
            Rs2ForwardSrc_C     <= Rs2ForwardSrcNext;
        end

    end

    always_comb begin

        Rs1ForwardSrcNext       = HighLevelControl::Rs1_NO_FORWARD;
        Rs2ForwardSrcNext       = HighLevelControl::Rs2_NO_FORWARD;

        StallPC                 = 1'b0;
        StallIR                 = 1'b0;
        FlushRC                 = 1'b0;

        //if forwarding from C stage
        if (RegWrite_C & (rd1Adr_C != 0) & (rs1Adr_R == rd1Adr_C)) begin

            //if its a load then must delay a cycle
            if(MemEn_C) begin

                StallPC             = 1'b1;
                StallIR             = 1'b1;
                FlushRC             = 1'b1;
                Rs1ForwardSrcNext   = HighLevelControl::rs1ForwardSrc'('x);

            end else begin

                Rs1ForwardSrcNext   = HighLevelControl::Rs1_ComputeResult;

            end
        end else if (RegWrite_M & (rd1Adr_M != 0) & (rs1Adr_R == rd1Adr_M)) begin

            Rs1ForwardSrcNext       = HighLevelControl::Rs1_Rd1W;

        end
        //if forwarding from C stage
        if (RegWrite_C & (rd1Adr_C != 0) & (rs2Adr_R == rd1Adr_C)) begin

            //if its a load then must delay a cycle
            if(MemEn_C) begin

                StallPC             = 1'b1;
                StallIR             = 1'b1;
                FlushRC             = 1'b1;
                Rs2ForwardSrcNext   = HighLevelControl::rs2ForwardSrc'('x);

            end else begin

                Rs2ForwardSrcNext   = HighLevelControl::Rs2_ComputeResult;

            end
        end else if(RegWrite_M & (rd1Adr_M != 0) & (rs2Adr_R == rd1Adr_M)) begin

            Rs2ForwardSrcNext       = HighLevelControl::Rs2_Rd1W;

        end

    end

endmodule
`endif
