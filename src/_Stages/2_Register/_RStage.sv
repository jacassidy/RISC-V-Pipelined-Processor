//James Kaden Cassidy jkc.cassidy@gmail.com 1/2/2026

`include "parameters.svh"

module _RStage (
    input  logic                          clk,
    input  logic                          reset,

    // From IR pipeline regs (in computeCore)
    input  logic [`WORD_SIZE-1:0]         Instr_R,
    input  logic [`XLEN-1:0]              PC_R,
    input  logic [`XLEN-1:0]              PCp4_R,
    input  logic                          ValidInstruction_R,

    // From W stage back into regfile
    input  logic                          RegWrite_W,
    input  logic [$clog2(`WORD_SIZE)-1:0]  rd1Adr_W,
    input  logic [`XLEN-1:0]              Rd1_W,

    // For hazard/PC update logic in computeCore
    output logic [$clog2(`WORD_SIZE)-1:0]  rs1Adr_R,
    output logic [$clog2(`WORD_SIZE)-1:0]  rs2Adr_R,
    output logic [$clog2(`WORD_SIZE)-1:0]  rd1Adr_R,
    output logic [`XLEN-1:0]               PCpImm_R,

    output HighLevelControl::pcSrc         PCSrc_R,
    output HighLevelControl::conditionalPCSrc ConditionalPCSrc_R,

    // === Outputs that feed RC pipeline regs (kept in computeCore) ===
    // Data bundle
    output logic [`XLEN-1:0]               AluOperandA_R,
    output logic [`XLEN-1:0]               AluOperandB_R,
    output logic [`XLEN-1:0]               Passthrough_R,

    // Control / flags
    output logic                          AluOperandAForwardEn_R,
    output logic                          AluOperandBForwardEn_R,
    output HighLevelControl::aluOperation  AluOperation_R,
    output HighLevelControl::computeSrc    ComputeSrc_R,

    output logic                          MemEn_R,
    output logic                          MemWriteEn_R,
    output HighLevelControl::storeType     StoreType_R,

    output logic                          RegWrite_R,
    output HighLevelControl::resultSrc     ResultSrc_R,
    output HighLevelControl::truncType     TruncType_R

`ifdef ZICSR
    ,
    output logic                          CSREn_R,
    output HighLevelControl::csrOp        CSROp_R
`endif
);

    HighLevelControl::immSrc                ImmSrcA_R, ImmSrcB_R;
    HighLevelControl::aluSrc                AluSrcA_R, AluSrcB_R;
    HighLevelControl::passthroughSrc        PassthroughSrc_R;

    logic[`XLEN-1:0]                        ImmA_R, ImmB_R;
    logic[`XLEN-1:0]                        Rs1_R, Rs2_R;

    //Bus assignments
    assign rs1Adr_R     = Instr_R[19:15];
    assign rs2Adr_R     = Instr_R[24:20];
    assign rd1Adr_R     = Instr_R[11:7];

    //Controller
    controller Controller(.Instr_R,
        .PCSrc_R, .ConditionalPCSrc_R, .RegWrite_R, .ImmSrcA_R, .ImmSrcB_R, .PassthroughSrc_R, .AluSrcA_R, .AluSrcB_R,
        .AluOperation_R, .ComputeSrc_R, .MemEn_R, .MemWriteEn_R, .StoreType_R, .ResultSrc_R, .TruncType_R
        `ifdef ZICSR
        ,.CSREn_R,
        .CSROp_R
        `endif
        );

    //Register File
    registerFile #(.REGISTER_COUNT(`WORD_SIZE)) RegisterFile(
        .clk, .reset, .WriteEn(RegWrite_W), .rs1Adr(rs1Adr_R), .rs2Adr(rs2Adr_R),
        .rd1Adr(rd1Adr_W), .Rd1(Rd1_W), .Rs1(Rs1_R), .Rs2(Rs2_R)
    );

    //ALU Src A Mux
    always_comb begin
        casex(AluSrcA_R)
            HighLevelControl::Rs:   AluOperandA_R = Rs1_R;
            HighLevelControl::Imm:  AluOperandA_R = ImmA_R;
            default:                AluOperandA_R = 'x;
        endcase
    end

    assign AluOperandAForwardEn_R = AluSrcA_R == HighLevelControl::Rs;

    //ALU Src B Mux
    always_comb begin
        casex(AluSrcB_R)
            HighLevelControl::Rs:   AluOperandB_R = Rs2_R;
            HighLevelControl::Imm:  AluOperandB_R = ImmB_R;
            default:                AluOperandB_R = 'x;
        endcase
    end

    assign AluOperandBForwardEn_R = AluSrcB_R == HighLevelControl::Rs;

    //Immediate Extender
    immediateExtender ImmediateExtenderA(.ImmSrc(ImmSrcA_R), .Instr(Instr_R), .Imm(ImmA_R));
    immediateExtender ImmediateExtenderB(.ImmSrc(ImmSrcB_R), .Instr(Instr_R), .Imm(ImmB_R));

    //Jump / Branch Adder
    assign PCpImm_R = ImmB_R + PC_R;

    //Passthrough Mux
    always_comb begin
        casex(PassthroughSrc_R)
            HighLevelControl::PCpImm:       Passthrough_R = PCpImm_R;
            HighLevelControl::PCp4:         Passthrough_R = PCp4_R;
            HighLevelControl::WriteData:    Passthrough_R = Rs2_R;
            HighLevelControl::LoadImm:      Passthrough_R = ImmB_R;

            default:                        Passthrough_R = 'x;
        endcase
    end

endmodule
