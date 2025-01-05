//James Kaden Cassidy jkc.cassidy@gmail.com 1/5/2025

`include "parameters.svh"

module hazzardUnit #(

)(
    input   logic                               clk,
    input   logic                               reset,

    input   logic[$clog2(`WORD_SIZE)-1:0]       rs1Adr_R,
    input   logic[$clog2(`WORD_SIZE)-1:0]       rs2Adr_R,

    input   logic[$clog2(`WORD_SIZE)-1:0]       rd1Adr_C,

    input   logic                               MemEn_C,
    input   logic                               RegWrite_C

    output  HighLevelControl::rs1ForwardSrc     Rs1ForwardSrc,
    output  HighLevelControl::rs21ForwardSrc    Rs2ForwardSrc,

    output  logic                               FlushCM,
    output  logic                               StallPC,
    output  logic                               StallIR,
    output  logic                               StallRC

);

    HighLevelControl::rs1ForwardSrc     Rs1ForwardSrcNext;
    HighLevelControl::rs21ForwardSrc    Rs2ForwardSrcNext;

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
                if (RegWrite_C) begin
                    //if register is being written determine the forwarding
                    if (rs1Adr_R == rd1Adr_C) begin
                        //if its a load then must delay a cycle
                        if(MemEn) begin
                            HazzardStateNext = LoadStall;
                            Rs1ForwardSrcNext = HighLevelControl::Rs1_MEMORY;
                        end else 
                            Rs1ForwardSrcNext = HighLevelControl::Rs1_COMPUTE;
                    end

                    if (rs2Adr_R == rd1Adr_C) begin
                        //if its a load then must delay a cycle
                        if(MemEn) begin
                            HazzardStateNext = LoadStall;
                            Rs2ForwardSrcNext = HighLevelControl::Rs2_MEMORY;
                        end else 
                            Rs2ForwardSrcNext = HighLevelControl::Rs2_COMPUTE;
                    end
                end
            end

            LoadStall: begin
                FlushCM             = 1'b1;
                StallPC             = 1'b1;
                StallIR             = 1'b1;
                StallRC             = 1'b1;

                //absolutely genious move to reuse the same flop twice during the stall to propogate a signal two clock cycles
                Rs1ForwardSrcNext = Rs1ForwardSrc
                Rs2ForwardSrcNext = Rs1ForwardSrc
            end
        endcase
    end

endmodule