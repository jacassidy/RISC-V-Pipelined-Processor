//James Kaden Cassidy jkc.cassidy@gmail.com 1/2/2026

`include "parameters.svh"

module WStage (
    input  logic [`XLEN-1:0]              ComputeResult_W,
    input  logic [`XLEN-1:0]              MemReadData_W,
    input  HighLevelControl::resultSrc     ResultSrc_W,
    input  HighLevelControl::truncType     TruncType_W,
    input  logic [$clog2(`XLEN/8)-1:0]     TruncSrc_W,

    output logic [`XLEN-1:0]              Result_W,
    output logic [`XLEN-1:0]              Rd1_W
);
    //Result Select Mux
    always_comb begin
        casex(ResultSrc_W)
            HighLevelControl::Memory:   Result_W = MemReadData_W;
            HighLevelControl::Compute:  Result_W = ComputeResult_W;

            default:                    Result_W = 'x;
        endcase
    end


    //Write Result to Register
    truncator Truncator(.TruncType(TruncType_W), .TruncSrc(TruncSrc_W), .InputData(Result_W), .TruncResult(Rd1_W));

endmodule
