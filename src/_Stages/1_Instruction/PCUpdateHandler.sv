//James Kaden Cassidy jkc.cassidy@gmail.com 12/23/2024

module pcUpdateHandler #(
    BIT_COUNT
)(
    input HighLevelControl::pcSrc PCSrcPostConditional_C,
    input HighLevelControl::pcSrc PCSrc_R,

    //****NEEDS HAZZARD TO ASSESS PREDICTION***//
    input logic Predict,
    input logic[BIT_COUNT-1:0] Prediction,
    input logic PredictionCorrect_C, //Current branch/Jump in C stage was predicted correctly, thus Jump in R should be considered

    input logic[BIT_COUNT-1:0] PCp4,
    input logic[BIT_COUNT-1:0] AluAdd_C,
    input logic[BIT_COUNT-1:0] PCpImm_R,
    input logic[BIT_COUNT-1:0] UpdatedPC_C,

    output logic[BIT_COUNT-1:0] PCNext
);
    import HighLevelControl::*;

    always_comb begin
        //C stage first Prio
        if(PCSrc_C === pcSrc::Branch_C || PCSrc_C === pcSrc::Jump_C) begin
            if(PredictionCorrect_C && PCSrc_R === pcSrc::Jump_R) begin
                //If branch/jump predicted correctly and Jump_R in R stage, take the jump instead
                PCNext = PCpImm_R;
            end else begin
                //If branch/jump was wrong then itll be flushed, take current
                if(PCSrc_C === pcSrc::Branch_C) begin
                    PCNext = UpdatedPC_C;
                end

                if(PCSrc_C === pcSrc::Jump_C) begin
                    PCNext = AluAdd_C;
                end
            end
        end
        //R stage second Prio
        else if(PCSrc_R === pcSrc::Jump_R)  PCNext = PCpImm_R;
        else                                PCNext = PCp4;
    end

endmodule