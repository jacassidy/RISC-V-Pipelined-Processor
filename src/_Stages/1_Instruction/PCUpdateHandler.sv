//James Kaden Cassidy jkc.cassidy@gmail.com 12/23/2024

`include "parameters.svh"

module pcUpdateHandler #(

)(
    input   HighLevelControl::pcSrc                   PCSrc_R,
    input   HighLevelControl::pcSrc                   PCSrcPostConditional_C,

    //****NEEDS HAZZARD TO ASSESS PREDICTION***//
    input   logic                   Predict,
    input   logic[`XLEN-1:0]        Prediction,
    input   logic                   PredictionCorrect_R,
    input   logic                   PredictionCorrect_C, //Current branch/Jump in C stage was predicted correctly, thus Jump in R should be considered

    input   logic[`XLEN-1:0]   PCp4_I,
    input   logic[`XLEN-1:0]   AluAdd_C,
    input   logic[`XLEN-1:0]   PCpImm_R,
    input   logic[`XLEN-1:0]   UpdatedPC_C,

    output logic[`XLEN-1:0]    PCNext_I

    `ifdef PIPELINED
        ,
        output  logic               FlushIR,
        output  logic               FlushRC
    `endif
);

    always_comb begin
        `ifdef PIPELINED
            FlushIR = 1'b0;
            FlushRC = 1'b0;
        `endif

        //C stage first Prio
        if(PCSrcPostConditional_C == HighLevelControl::Branch_C || PCSrcPostConditional_C == HighLevelControl::Jump_C) begin

            if(PredictionCorrect_C && PCSrc_R == HighLevelControl::Jump_R && ~PredictionCorrect_R) begin
                //If branch/jump predicted correctly and Jump_R in R stage and R stage jump incorrectly predicted, take the R stage jump
                    PCNext_I = {PCpImm_R[`XLEN-1:1], 1'b0};

                    `ifdef PIPELINED
                        FlushIR = 1'b1;
                    `endif

            end else begin
                //If branch/jump was wrong then itll be flushed, take current

                `ifdef PIPELINED
                    FlushIR = 1'b1;
                    FlushRC = 1'b1;
                `endif

                if(PCSrcPostConditional_C == HighLevelControl::Branch_C) begin
                    PCNext_I = {UpdatedPC_C[`XLEN-1:1], 1'b0};

                end else if(PCSrcPostConditional_C == HighLevelControl::Jump_C) begin
                    PCNext_I = {AluAdd_C[`XLEN-1:1], 1'b0};
                end else begin
                    PCNext_I = 'x; // Should never happen
                end
            end

        end
        //R stage second Prio
        else if(PCSrc_R == HighLevelControl::Jump_R && ~PredictionCorrect_R) begin
            //if source is Jump_R but we didnt already correctly predict the jump then jump
                    PCNext_I = {PCpImm_R[`XLEN-1:1], 1'b0};

                    `ifdef PIPELINED
                        FlushIR = 1'b1;
                    `endif
        end else
            //PC + 4 is default
                    PCNext_I = {PCp4_I[`XLEN-1:1], 1'b0};
    end

endmodule
