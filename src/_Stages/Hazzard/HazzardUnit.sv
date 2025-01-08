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

    output  HighLevelControl::rs1ForwardSrc     Rs1ForwardSrc_C,
    output  HighLevelControl::rs2ForwardSrc     Rs2ForwardSrc_C,

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
            Rs1ForwardSrc_C     <= HighLevelControl::Rs1_NO_FORWARD;
            Rs2ForwardSrc_C     <= HighLevelControl::Rs2_NO_FORWARD;
        end else begin
            Rs1ForwardSrc_C     <= Rs1ForwardSrcNext;
            Rs2ForwardSrc_C     <= Rs2ForwardSrcNext;
        end

    end
    
    typedef enum logic {Listening, LoadStall} hazzardState;

    hazzardState HazzardState, HazzardStateNext;

    typedef enum logic[1:0] {Rs1_Load, Rs1_Compute_Result, Rs1_Trunc_Result, Rs1_None} rs1ForwardType;
    typedef enum logic[1:0] {Rs2_Load, Rs2_Compute_Result, Rs2_Trunc_Result, Rs2_None} rs2ForwardType;

    rs1ForwardType Rs1ForwardType;
    rs2ForwardType Rs2ForwardType;

    //State machine for Load hazzard due to stall to remove accidental forwarding
    always_ff @(posedge clk) begin
        if(reset)   HazzardState <= Listening;
        else        HazzardState <= HazzardStateNext;
    end


    always_comb begin

        Rs1ForwardSrcNext       = HighLevelControl::Rs1_NO_FORWARD;
        Rs2ForwardSrcNext       = HighLevelControl::Rs2_NO_FORWARD;
        
        FlushCM                 = 1'b0;
        StallPC                 = 1'b0;
        StallIR                 = 1'b0;
        StallRC                 = 1'b0;

        HazzardStateNext        = Listening;

        Rs1ForwardType          = Rs1_None;
        Rs2ForwardType          = Rs2_None;

        case(HazzardState)

            Listening: begin

                //if forwarding from C stage
                if (RegWrite_C && rd1Adr_C != 0 && rs1Adr_R == rd1Adr_C) begin

                    //if its a load then must delay a cycle
                    if(MemEn_C) begin

                        HazzardStateNext    = LoadStall;
                        Rs1ForwardSrcNext   = HighLevelControl::Rs1_Rd1W;
                        Rs1ForwardType      = Rs1_Load;

                    end else begin

                        Rs1ForwardSrcNext   = HighLevelControl::Rs1_ComputeResult;
                        Rs1ForwardType      = Rs1_Compute_Result;

                    end
                end else if (RegWrite_M && rd1Adr_M != 0 && rs1Adr_R == rd1Adr_M) begin

                    Rs1ForwardSrcNext       = HighLevelControl::Rs1_Rd1W;
                    Rs1ForwardType          = Rs1_Trunc_Result;

                end
                //if forwarding from C stage
                if (RegWrite_C && rd1Adr_C != 0 && rs2Adr_R == rd1Adr_C) begin    

                    //if its a load then must delay a cycle
                    if(MemEn_C) begin

                        HazzardStateNext    = LoadStall;
                        Rs2ForwardSrcNext   = HighLevelControl::Rs2_Rd1W;
                        Rs2ForwardType      = Rs2_Load;

                    end else begin

                        Rs2ForwardSrcNext   = HighLevelControl::Rs2_ComputeResult;
                        Rs2ForwardType      = Rs2_Compute_Result;

                    end
                end else if(RegWrite_M && rd1Adr_M != 0 && rs2Adr_R == rd1Adr_M) begin

                    Rs2ForwardSrcNext       = HighLevelControl::Rs2_Rd1W;
                    Rs2ForwardType          = Rs2_Trunc_Result;

                end

                //Solves forwarding hazzard bellow:
                //  addi x1, x0, 10
                //  lw x2, 0(x0)
                //  sub x0, x1, x2
                //if there is a load in C stage and there is desire to forward due to an rd1Adr_M hazzard, then stall I stage
                if (HazzardStateNext == LoadStall) begin
                    if(Rs1ForwardType == Rs1_Trunc_Result) Rs1ForwardSrcNext = HighLevelControl::Rs1_Rd1PostW;
                    if(Rs2ForwardType == Rs2_Trunc_Result) Rs2ForwardSrcNext = HighLevelControl::Rs2_Rd1PostW;
                end

            end

            LoadStall: begin
                FlushCM             = 1'b1;
                StallPC             = 1'b1;
                StallIR             = 1'b1;
                StallRC             = 1'b1;

                //absolutely genious move to reuse the same flop twice during the stall to propogate a signal two clock cycles
                Rs1ForwardSrcNext       = Rs1ForwardSrc_C;
                Rs2ForwardSrcNext       = Rs2ForwardSrc_C;
            end
        endcase
    end

endmodule
`endif