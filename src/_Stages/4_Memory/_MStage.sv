//James Kaden Cassidy jkc.cassidy@gmail.com 1/2/2026

`include "parameters.svh"

module _MStage (
    // From CM pipeline regs (in computeCore)
    input  logic [`XLEN-1:0]              ComputeResult_M,
    input  logic [`XLEN-1:0]              MemWriteData_M,

    input  logic                          MemEn_M,
    input  logic                          MemWriteEn_M,
    input  logic [(`XLEN/8)-1:0]          MemWriteByteEn_M,

    // External memory read data
    input  logic [`XLEN-1:0]              External_MemReadData,

    // External memory interface outputs
    output logic                          External_MemEn,
    output logic                          External_MemWriteEn,
    output logic [(`XLEN/8)-1:0]          External_MemWriteByteEn,
    output logic [`XLEN-1:0]              External_MemAdr,
    output logic [`XLEN-1:0]              External_MemWriteData,

    // === Outputs that feed MW pipeline regs (kept in computeCore) ===
    output logic [`XLEN-1:0]              MemReadData_M,
    output logic [$clog2(`XLEN/8)-1:0]    TruncSrc_M
);

    ////Memory Cache handled externally////
    assign External_MemEn           = MemEn_M;
    assign External_MemWriteEn      = MemWriteEn_M;
    assign External_MemAdr          = {ComputeResult_M[`XLEN-1 : $clog2(`XLEN/8)], {($clog2(`XLEN/8)) {1'b0}}};
    assign External_MemWriteData    = MemWriteData_M;
    assign External_MemWriteByteEn  = MemWriteByteEn_M;

    assign MemReadData_M            = External_MemReadData;


    assign TruncSrc_M               = ComputeResult_M[$clog2(`XLEN/8)-1 : 0];
endmodule
