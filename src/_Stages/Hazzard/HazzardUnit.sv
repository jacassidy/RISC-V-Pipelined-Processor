//James Kaden Cassidy jkc.cassidy@gmail.com 1/5/2025

`include "parameters.svh"

`ifdef PIPELINED
module hazzardUnit #(

)(
    input   logic                               clk,
    input   logic                               reset,

    input   logic[$clog2(`WORD_SIZE)-1:0]       rs1Adr_R,
    input   logic[$clog2(`WORD_SIZE)-1:0]       rs2Adr_R,

    input   logic[$clog2(`WORD_SIZE)-1:0]       rd1Adr_C,
    input   logic[$clog2(`WORD_SIZE)-1:0]       rd1Adr_M,

    input   logic                               MemEn_C,
    input   logic                               RegWrite_C,
    input   logic                               RegWrite_M,

    output  HighLevelControl::rs1ForwardSrc     Rs1ForwardSrc,
    output  HighLevelControl::rs2ForwardSrc     Rs2ForwardSrc,

    output  logic                               FlushCM,
    output  logic                               StallPC,
    output  logic                               StallIR,
    output  logic                               StallRC

);

    HighLevelControl::rs1ForwardSrc     Rs1ForwardSrcNext;
    HighLevelControl::rs2ForwardSrc     Rs2ForwardSrcNext;

    //Forwarding singals need to be delayed one clock cycle due to forwarding being determined in R stage of next instruction
    always_ff @(posedge clk) begin

        if(reset) begin
            Rs1ForwardSrc <= HighLevelControl::Rs1_NO_FORWARD;
            Rs2ForwardSrc <= HighLevelControl::Rs2_NO_FORWARD;
        end else begin
            Rs1ForwardSrc <= Rs1ForwardSrcNext;
            Rs2ForwardSrc <= Rs2ForwardSrcNext;
        end

    end
    
    typedef enum logic {Listening, LoadStall} hazzardState;

    hazzardState HazzardState, HazzardStateNext;

    //State machine for Load hazzard due to stall to remove accidental forwarding
    always_ff @(posedge clk) begin
        if(reset)   HazzardState <= Listening;
        else        HazzardState <= HazzardStateNext;
    end


    always_comb begin

        Rs1ForwardSrcNext   = HighLevelControl::Rs1_NO_FORWARD;
        Rs2ForwardSrcNext   = HighLevelControl::Rs2_NO_FORWARD;
        
        FlushCM             = 1'b0;
        StallPC             = 1'b0;
        StallIR             = 1'b0;
        StallRC             = 1'b0;

        HazzardStateNext    = Listening;

        case(HazzardState)

            Listening: begin
                //if forwarding from C stage
                if (RegWrite_C && rd1Adr_C != 0 && rs1Adr_R == rd1Adr_C) begin

                    //if its a load then must delay a cycle
                    if(MemEn_C) begin

                        HazzardStateNext = LoadStall;
                        Rs1ForwardSrcNext = HighLevelControl::Rs1_TRUNCATED_RESULT;

                    end else begin

                        Rs1ForwardSrcNext = HighLevelControl::Rs1_COMPUTE_RESULT;

                    end
                end else if (RegWrite_M && rd1Adr_M != 0 && rs1Adr_R == rd1Adr_M) begin

                    Rs1ForwardSrcNext = HighLevelControl::Rs1_TRUNCATED_RESULT;

                end
                //if forwarding from C stage
                if (RegWrite_C && rd1Adr_C != 0 && rs2Adr_R == rd1Adr_C) begin    

                    //if its a load then must delay a cycle
                    if(MemEn_C) begin

                        HazzardStateNext = LoadStall;
                        Rs2ForwardSrcNext = HighLevelControl::Rs2_TRUNCATED_RESULT;

                    end else begin

                        Rs2ForwardSrcNext = HighLevelControl::Rs2_COMPUTE_RESULT;

                    end
                end else if(RegWrite_M && rd1Adr_M != 0 && rs2Adr_R == rd1Adr_M) begin

                    Rs2ForwardSrcNext = HighLevelControl::Rs2_TRUNCATED_RESULT;

                end

            end

            LoadStall: begin
                FlushCM             = 1'b1;
                StallPC             = 1'b1;
                StallIR             = 1'b1;
                StallRC             = 1'b1;

                //absolutely genious move to reuse the same flop twice during the stall to propogate a signal two clock cycles
                Rs1ForwardSrcNext = Rs1ForwardSrc;
                Rs2ForwardSrcNext = Rs2ForwardSrc;
            end
        endcase
    end

endmodule
`endif