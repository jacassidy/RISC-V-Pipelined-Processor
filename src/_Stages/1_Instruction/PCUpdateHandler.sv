//James Kaden Cassidy jkc.cassidy@gmail.com 12/23/2024

`include "parameters.svh"

import HighLevelControl::*;

module pcUpdateHandler #(
    
)(
    input   pcSrc                   PCSrc_R,
    input   pcSrc                   PCSrcPostConditional_C,
    
    //****NEEDS HAZZARD TO ASSESS PREDICTION***//
    input   logic                   Predict,
    input   logic[`BIT_COUNT-1:0]    Prediction,
    input   logic                   PredictionCorrect_C, //Current branch/Jump in C stage was predicted correctly, thus Jump in R should be considered

    input   logic[`BIT_COUNT-1:0]    PCp4,
    input   logic[`BIT_COUNT-1:0]    AluAdd_C,
    input   logic[`BIT_COUNT-1:0]    PCpImm_R,
    input   logic[`BIT_COUNT-1:0]    UpdatedPC_C,

    output logic[`BIT_COUNT-1:0] PCNext
);

    always_comb begin
        //C stage first Prio
        if(PCSrcPostConditional_C == Branch_C || PCSrcPostConditional_C == Jump_C) begin
            if(PredictionCorrect_C && PCSrc_R == Jump_R) begin
                //If branch/jump predicted correctly and Jump_R in R stage, take the jump instead
                                                        PCNext = {PCpImm_R[`BIT_COUNT-1:1], 1'b0};
            end else begin
                //If branch/jump was wrong then itll be flushed, take current
                if(PCSrcPostConditional_C == Branch_C)  PCNext = {UpdatedPC_C[`BIT_COUNT-1:1], 1'b0};
    
                if(PCSrcPostConditional_C == Jump_C)    PCNext = {AluAdd_C[`BIT_COUNT-1:1], 1'b0};
            end
        end
        //R stage second Prio
        else if(PCSrc_R == Jump_R)                      PCNext = {PCpImm_R[`BIT_COUNT-1:1], 1'b0};
        else                                            PCNext = {PCp4[`BIT_COUNT-1:1], 1'b0};
    end

endmodule