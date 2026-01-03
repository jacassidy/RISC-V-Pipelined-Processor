//James Kaden Cassidy jkc.cassidy@gmail.com 12/19/2024

`include "parameters.svh"

module computeCore #(

) (
    input   logic                  clk,
    input   logic                  reset,

    //To handle memory / chache externally
    output  logic[`XLEN-1:0]       External_PC,             //Instruction Cache

    output  logic                  External_MemEn,
    output  logic                  External_MemWriteEn,     //Command Memory to write
    output  logic[(`XLEN/8)-1:0]   External_MemWriteByteEn, //Bytes to be written
    output  logic[`XLEN-1:0]       External_MemAdr,         //Memory Address
    output  logic[`XLEN-1:0]       External_MemWriteData,   //Memory to be saved

    input   logic[`WORD_SIZE-1:0]  External_Instr,
    input   logic[`XLEN-1:0]       External_MemReadData
);



                        ////****I Stage****////
    logic                                   ValidInstruction_I;

    logic[`XLEN-1:0]                        PCNext_I, PCp4_I, PC_I;
    logic[`WORD_SIZE-1:0]                   Instr_I;

                        ////****R Stage****////
    logic                                   ValidInstruction_R;

    logic[`WORD_SIZE-1:0]                   Instr_R;
    logic[`XLEN-1:0]                        PCp4_R, PC_R, PCpImm_R, Passthrough_R;
    logic[$clog2(`WORD_SIZE)-1:0]           rs1Adr_R, rs2Adr_R;
    logic[$clog2(`WORD_SIZE)-1:0]           rd1Adr_R;

    //Controller Signals
    HighLevelControl::pcSrc                 PCSrc_R;

    //C
    logic[`XLEN-1:0]                        AluOperandA_R, AluOperandB_R;
    HighLevelControl::conditionalPCSrc      ConditionalPCSrc_R;

    logic                                   AluOperandAForwardEn_R, AluOperandBForwardEn_R;
    HighLevelControl::aluOperation          AluOperation_R;
    HighLevelControl::computeSrc            ComputeSrc_R;

    //M
    logic                                   MemEn_R, MemWriteEn_R;
    HighLevelControl::storeType             StoreType_R;

    //W
    logic                                   RegWrite_R;
    HighLevelControl::resultSrc             ResultSrc_R;
    HighLevelControl::truncType             TruncType_R;

    //ZICSR
    `ifdef ZICSR
    logic                                   CSREn_R;
    HighLevelControl::csrOp                 CSROp_R;
    `endif

                        ////****C Stage****////
    logic                                   ValidInstruction_C;

    logic[`XLEN-1:0]                        Passthrough_C, AluOperandA_C, AluOperandB_C, AluResult_C, ComputeResult_C;
    logic[`XLEN-1:0]                        MemWriteData_C;
    logic[$clog2(`WORD_SIZE)-1:0]           rd1Adr_C;

    HighLevelControl::pcSrc                 PCSrcPostConditional_C;

    //Controller Signals
    HighLevelControl::pcSrc                 PCSrc_C;
    HighLevelControl::conditionalPCSrc      ConditionalPCSrc_C;

    logic                                   AluOperandAForwardEn_C, AluOperandBForwardEn_C;
    HighLevelControl::aluOperation          AluOperation_C;
    HighLevelControl::computeSrc            ComputeSrc_C;

    //M
    logic                                   MemEn_C, MemWriteEn_C;
    HighLevelControl::storeType             StoreType_C;
    logic[(`XLEN/8)-1:0]                    MemWriteByteEn_C;

    //W
    logic                                   RegWrite_C;
    HighLevelControl::resultSrc             ResultSrc_C;
    HighLevelControl::truncType             TruncType_C;

    //ZICSR
    `ifdef ZICSR
    logic                                   CSREn_C;
    HighLevelControl::csrOp                 CSROp_C;
    `endif

                        ////****M Stage****////
    logic                                   ValidInstruction_M;

    logic[`XLEN-1:0]                        ComputeResult_M, MemWriteData_M, MemReadData_M;
    logic[$clog2(`WORD_SIZE)-1:0]           rd1Adr_M;

    //Controller Signals
    logic                                   MemEn_M, MemWriteEn_M;
    logic[(`XLEN/8)-1:0]                    MemWriteByteEn_M;

    //W
    logic                                   RegWrite_M;
    HighLevelControl::resultSrc             ResultSrc_M;
    HighLevelControl::truncType             TruncType_M;
    logic[$clog2(`XLEN/8)-1:0]              TruncSrc_M;

                        ////****W Stage****////
    logic                                   ValidInstruction_W;

    logic[`XLEN-1:0]                        Rd1_W, Result_W, ComputeResult_W, MemReadData_W;
    logic[$clog2(`WORD_SIZE)-1:0]           rd1Adr_W;

    //Controller Signals
    logic                                   RegWrite_W;
    HighLevelControl::resultSrc             ResultSrc_W;
    HighLevelControl::truncType             TruncType_W;
    logic[$clog2(`XLEN/8)-1:0]              TruncSrc_W;

                        ////****HAZZARDS****////
    `ifdef PIPELINED
        HighLevelControl::rs1ForwardSrc     Rs1ForwardSrc_C;
        HighLevelControl::rs2ForwardSrc     Rs2ForwardSrc_C;

        logic                               FlushIR, FlushRC, FlushCM;
        logic                               StallPC, StallIR, StallRC;

        logic                               LoadAfterForward_C;
        logic[`XLEN-1:0]                    Rd1_PostW;
    `endif

    ////                        **** I STAGE ****                       ////

    _IStage IStage (
        .clk, .reset,
        .PCNext_I,
    `ifdef PIPELINED
        .StallPC,
    `endif
        .External_PC(External_PC),
        .External_Instr(External_Instr),
        .PC_I, .PCp4_I, .Instr_I, .ValidInstruction_I
);

    //Pipeline Registers
    `ifdef PIPELINED

        //Data
        flopRS #(.WIDTH(`XLEN * 2)) DataFlopIR(.clk, .reset, .stall(StallIR),
                .D({PC_I, PCp4_I}),
                .Q({PC_R, PCp4_R})
            );

        //Flush instruction to all zeros to flush
        flopRFS #(.WIDTH(`WORD_SIZE)) InstructionFlopIR(.clk, .reset, .flush(FlushIR), .stall(StallIR),
                .D({Instr_I}),
                .Q({Instr_R})
            );

        flopRFS #(.WIDTH(
            $bits({ValidInstruction_I})
        )) ArchitecturalSignalFlopIR(.clk, .reset, .stall(StallIR), .flush(FlushIR),
                .D({ValidInstruction_I}),
                .Q({ValidInstruction_R})
            );

    `else
        assign Instr_R              = Instr_I;
        assign PC_R                 = PC_I;
        assign PCp4_R               = PCp4_I;
        assign ValidInstruction_R   = ValidInstruction_I;
    `endif

    ////                        **** R STAGE ****                       ////

    _RStage RStage (
        .clk, .reset,
        .Instr_R, .PC_R, .PCp4_R, .ValidInstruction_R,

        .RegWrite_W,
        .rd1Adr_W,
        .Rd1_W,

        .rs1Adr_R, .rs2Adr_R, .rd1Adr_R,
        .PCpImm_R,
        .PCSrc_R, .ConditionalPCSrc_R,

        .AluOperandA_R, .AluOperandB_R, .Passthrough_R,
        .AluOperandAForwardEn_R, .AluOperandBForwardEn_R,
        .AluOperation_R, .ComputeSrc_R,
        .MemEn_R, .MemWriteEn_R, .StoreType_R,
        .RegWrite_R, .ResultSrc_R, .TruncType_R
    `ifdef ZICSR
        , .CSREn_R, .CSROp_R
    `endif
    );

    `ifdef PIPELINED

        //Data
        flopRS #(.WIDTH(`XLEN * 3 + $clog2(`WORD_SIZE))) DataFlopRC(.clk, .reset, .stall(StallRC),
                .D({AluOperandA_R, AluOperandB_R, Passthrough_R, rd1Adr_R}),
                .Q({AluOperandA_C, AluOperandB_C, Passthrough_C, rd1Adr_C})
            );

        //Signals
        flopRS #(.WIDTH(
            $bits({PCSrc_R, ConditionalPCSrc_R, AluOperandAForwardEn_R, AluOperandBForwardEn_R, AluOperation_R,
                    ComputeSrc_R, ResultSrc_R, TruncType_R})
        )) SignalFlopRC(.clk, .reset, .stall(StallRC),
                .D({PCSrc_R, ConditionalPCSrc_R, AluOperandAForwardEn_R, AluOperandBForwardEn_R, AluOperation_R,
                    ComputeSrc_R, ResultSrc_R, TruncType_R}),
                .Q({PCSrc_C, ConditionalPCSrc_C, AluOperandAForwardEn_C, AluOperandBForwardEn_C, AluOperation_C,
                    ComputeSrc_C, ResultSrc_C, TruncType_C})
            );

        //Architectural Signals
        flopRFS #(.WIDTH(
            $bits({MemEn_R, MemWriteEn_R, StoreType_R, RegWrite_R, ValidInstruction_R})
        )) ArchitecturalSignalFlopRC(.clk, .reset, .stall(StallRC), .flush(FlushRC),
                .D({MemEn_R, MemWriteEn_R, StoreType_R, RegWrite_R, ValidInstruction_R}),
                .Q({MemEn_C, MemWriteEn_C, StoreType_C, RegWrite_C, ValidInstruction_C})
            );

        //ZICSR Signals
        `ifdef ZICSR
        flopRFS #(.WIDTH(
            $bits({CSREn_R, CSROp_R})
        )) ZICSRSignalFlopRC(.clk, .reset, .stall(StallRC), .flush(FlushRC),
                .D({CSREn_R, CSROp_R}),
                .Q({CSREn_C, CSROp_C})
            );
        `endif

    `else

        //Data
        assign AluOperandA_C            = AluOperandA_R;
        assign AluOperandB_C            = AluOperandB_R;
        assign Passthrough_C            = Passthrough_R;
        assign rd1Adr_C                 = rd1Adr_R;

        //Signals
        assign ValidInstruction_C       = ValidInstruction_R;
        assign PCSrc_C                  = PCSrc_R;
        assign ConditionalPCSrc_C       = ConditionalPCSrc_R;
        assign AluOperandAForwardEn_C   = AluOperandAForwardEn_R;
        assign AluOperandBForwardEn_C   = AluOperandBForwardEn_R;
        assign AluOperation_C           = AluOperation_R;
        assign ComputeSrc_C             = ComputeSrc_R;
        assign MemEn_C                  = MemEn_R;
        assign MemWriteEn_C             = MemWriteEn_R;
        assign StoreType_C              = StoreType_R;
        assign ResultSrc_C              = ResultSrc_R;
        assign RegWrite_C               = RegWrite_R;
        assign TruncType_C              = TruncType_R;

        //ZICSR
        `ifdef ZICSR
        assign CSREn_C                  = CSREn_R;
        assign CSROp_C                  = CSROp_R;
        `endif

    `endif

    ////                        **** C STAGE ****                       ////
    _CStage CStage (
        .clk, .reset,

        .ValidInstruction_C,
        .Passthrough_C, .AluOperandA_C, .AluOperandB_C, .rd1Adr_C,
        .PCSrc_C, .ConditionalPCSrc_C,
        .AluOperandAForwardEn_C, .AluOperandBForwardEn_C,
        .AluOperation_C, .ComputeSrc_C,
        .MemEn_C, .MemWriteEn_C, .StoreType_C,
        .RegWrite_C, .ResultSrc_C, .TruncType_C,

    `ifdef ZICSR
        .CSREn_C, .CSROp_C,
    `endif

    `ifdef PIPELINED
        .Rs1ForwardSrc_C, .Rs2ForwardSrc_C,
        .ComputeResult_M,
        .Rd1_W,
        .Rd1_PostW,
    `endif

    `ifdef ZICNTR
        .ValidInstruction_W,
    `endif
        .AluResult_C,
        .PCSrcPostConditional_C,
        .ComputeResult_C,
        .MemWriteData_C,
        .MemWriteByteEn_C
    );

    `ifdef PIPELINED

        //Data
        flopR #(.WIDTH(`XLEN * 2 + $clog2(`WORD_SIZE))) DataFlopCM(.clk, .reset,
                .D({ComputeResult_C, MemWriteData_C, rd1Adr_C}),
                .Q({ComputeResult_M, MemWriteData_M, rd1Adr_M})
            );

        //Signals
        flopR #(.WIDTH(
            $bits({ResultSrc_C, TruncType_C})
        )) SignalFlopCM(.clk, .reset,
                .D({ResultSrc_C, TruncType_C}),
                .Q({ResultSrc_M, TruncType_M})
        );

        //Architectural Signals
        flopRF #(.WIDTH(
            $bits({MemEn_C, MemWriteEn_C, MemWriteByteEn_C, RegWrite_C, ValidInstruction_C})
        )) ArchitecturalSignalFlopCM(.clk, .reset, .flush(FlushCM),
                .D({MemEn_C, MemWriteEn_C, MemWriteByteEn_C, RegWrite_C, ValidInstruction_C}),
                .Q({MemEn_M, MemWriteEn_M, MemWriteByteEn_M, RegWrite_M, ValidInstruction_M})
        );

    `else

        //Data
        assign ComputeResult_M      = ComputeResult_C;
        assign MemWriteData_M       = MemWriteData_C;
        assign rd1Adr_M             = rd1Adr_C;

        //Signals
        assign ValidInstruction_M   = ValidInstruction_C;
        assign MemEn_M              = MemEn_C;
        assign MemWriteEn_M         = MemWriteEn_C;
        assign MemWriteByteEn_M     = MemWriteByteEn_C;
        assign ResultSrc_M          = ResultSrc_C;
        assign RegWrite_M           = RegWrite_C;
        assign TruncType_M          = TruncType_C;

    `endif

    ////                        **** M STAGE ****                       ////

    _MStage MStage (
        .ComputeResult_M,
        .MemWriteData_M,
        .MemEn_M, .MemWriteEn_M, .MemWriteByteEn_M,

        .External_MemReadData(External_MemReadData),

        .External_MemEn(External_MemEn),
        .External_MemWriteEn(External_MemWriteEn),
        .External_MemWriteByteEn(External_MemWriteByteEn),
        .External_MemAdr(External_MemAdr),
        .External_MemWriteData(External_MemWriteData),

        .MemReadData_M,
        .TruncSrc_M
    );

    `ifdef PIPELINED

        //Data
        flopR #(.WIDTH(2 * `XLEN + $clog2(`WORD_SIZE))) DataFlopMW(.clk, .reset,
                .D({ComputeResult_M, MemReadData_M, rd1Adr_M}),
                .Q({ComputeResult_W, MemReadData_W, rd1Adr_W})
            );

        //Signals
        flopR #(.WIDTH(
            $bits({ResultSrc_M, TruncType_M, TruncSrc_M})
        )) SignalFlopMW(.clk, .reset,
                .D({ResultSrc_M, TruncType_M, TruncSrc_M}),
                .Q({ResultSrc_W, TruncType_W, TruncSrc_W})
        );

        //Architectural Signals
        flopR #(.WIDTH(
            $bits({RegWrite_M, ValidInstruction_M})
        )) ArchitecturalSignalFlopMW(.clk, .reset,
                .D({RegWrite_M, ValidInstruction_M}),
                .Q({RegWrite_W, ValidInstruction_W})
        );

    `else

        //Data
        assign ComputeResult_W      = ComputeResult_M;
        assign MemReadData_W        = MemReadData_M;
        assign rd1Adr_W             = rd1Adr_M;

        //Signals
        assign ValidInstruction_W   = ValidInstruction_M;
        assign RegWrite_W           = RegWrite_M;
        assign ResultSrc_W          = ResultSrc_M;
        assign TruncType_W          = TruncType_M;
        assign TruncSrc_W           = TruncSrc_M;

    `endif

    ////                        **** W STAGE ****                       ////

    WStage WStage_i (
        .ComputeResult_W,
        .MemReadData_W,
        .ResultSrc_W,
        .TruncType_W,
        .TruncSrc_W,
        .Result_W,
        .Rd1_W
    );

    ////                        **** HAZZARDS ****                       ////
    logic PredictionCorrect_C;

    `ifdef PIPELINED
        //Prediction is only ever correct when there was a branch and it is not taken
        assign PredictionCorrect_C = PCSrcPostConditional_C != HighLevelControl::Branch_C && ConditionalPCSrc_C != HighLevelControl::NO_BRANCH;

        hazzardUnit HazzardUnit(.clk, .reset, .rs1Adr_R, .rs2Adr_R, .rd1Adr_C, .rd1Adr_M, .MemEn_C, .RegWrite_C, .RegWrite_M,
                                .Rs1ForwardSrc_C, .Rs2ForwardSrc_C, .FlushCM, .StallPC, .StallIR, .StallRC);

        flopR #(.WIDTH(`XLEN)) LoadAfterForwardFlop(.clk, .reset,
                .D(Rd1_W),
                .Q(Rd1_PostW)
            );
    `else
        assign PredictionCorrect_C  = 1'b0;
    `endif

    //PC Source Select Mux implemented with branch prediction
    pcUpdateHandler PCUpdateHandler(.PCSrc_R(PCSrc_R),
            .PCSrcPostConditional_C, .Predict(1'b0), .Prediction(`XLEN'b0), .PredictionCorrect_R(1'b0),
            .PredictionCorrect_C, .PCp4_I, .AluAdd_C(AluResult_C), .PCpImm_R, .UpdatedPC_C(Passthrough_C), .PCNext_I

            `ifdef PIPELINED
                , .FlushIR, .FlushRC
            `endif

            );

    `ifdef DEBUGGING

        // logic[$clog2(`WORD_SIZE)-1:0]   rs1Adr_C, rs2Adr_C;
        // logic[`XLEN-1:0]           Rs1_C, Rs2_C, Imm_C;

        // logic[$clog2(`WORD_SIZE)-1:0]   rs1Adr_M, rs2Adr_M;
        // logic[`XLEN-1:0]           Rs1_M, Rs2_M, Imm_M, AluHazzardSafeOperandA_M, AluHazzardSafeOperandB_M;
        // HighLevelControl::aluOperation  AluOperation_M;

        // logic[$clog2(`WORD_SIZE)-1:0]   rs1Adr_W, rs2Adr_W;
        // logic[`XLEN-1:0]           Rs1_W, Rs2_W, Imm_W, AluHazzardSafeOperandA_W, AluHazzardSafeOperandB_W, MemWriteData_W;
        // HighLevelControl::aluOperation  AluOperation_W;

        // flopR #(`XLEN * 3 + $clog2(`WORD_SIZE) * 2) DebugFlopRC (.clk, .reset,
        //     .D({rs1Adr_R, rs2Adr_R, Rs1_R, Rs2_R, Imm_R}),
        //     .Q({rs1Adr_C, rs2Adr_C, Rs1_C, Rs2_C, Imm_C})
        //     );

        // flopR #(`XLEN * 5 + $clog2(`WORD_SIZE) * 2 + $bits(AluOperation_M)) DebugFlopCM (.clk, .reset,
        //     .D({rs1Adr_C, rs2Adr_C, Rs1_C, Rs2_C, Imm_C, AluHazzardSafeOperandA_C, AluHazzardSafeOperandB_C, AluOperation_C}),
        //     .Q({rs1Adr_M, rs2Adr_M, Rs1_M, Rs2_M, Imm_M, AluHazzardSafeOperandA_M, AluHazzardSafeOperandB_M, AluOperation_M})
        //     );

        // flopR #(`XLEN * 6 + $clog2(`WORD_SIZE) * 2 + $bits(AluOperation_W)) DebugFlopMW (.clk, .reset,
        //     .D({rs1Adr_M, rs2Adr_M, Rs1_M, Rs2_M, Imm_M, AluHazzardSafeOperandA_M, AluHazzardSafeOperandB_M, MemWriteData_M, AluOperation_M}),
        //     .Q({rs1Adr_W, rs2Adr_W, Rs1_W, Rs2_W, Imm_W, AluHazzardSafeOperandA_W, AluHazzardSafeOperandB_W, MemWriteData_W, AluOperation_W})
        //     );

    `endif


endmodule
