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
    output  logic[(`XLEN/8)-1:0]   External_MemWriteByteEn,      //Bytes to be writen
    output  logic[`XLEN-1:0]       External_MemAdr,         //Memory Adress
    output  logic[`XLEN-1:0]       External_MemWriteData,   //Memory to be saved

    input   logic[`WORD_SIZE-1:0]  External_Instr,
    input   logic[`XLEN-1:0]       External_MemReadData
);



                        ////****I Stage****////
    logic[`XLEN-1:0]                    PCNext_I, PCp4_I, PC_I;
    logic[`WORD_SIZE-1:0]               Instr_I;

                        ////****R Stage****////
    logic[`WORD_SIZE-1:0]               Instr_R;
    logic[`XLEN-1:0]                    PCp4_R, PC_R, Rs1_R, Rs2_R, Imm_R, PCpImm_R, Passthrough_R;
    logic[$clog2(`WORD_SIZE)-1:0]       rs1Adr_R, rs2Adr_R;
    logic[$clog2(`WORD_SIZE)-1:0]       rd1Adr_R;

    //Controller Signals
    HighLevelControl::immSrc            ImmSrc_R;
    HighLevelControl::aluSrcB           AluSrcB_R;
    HighLevelControl::passthroughSrc    PassthroughSrc_R;
    HighLevelControl::pcSrc             PCSrc_R;

    //C
    logic[`XLEN-1:0]                    AluOperandA_R, AluOperandB_R;
    HighLevelControl::conditionalPCSrc  ConditionalPCSrc_R;

    logic                               AluOperandBForwardEn_R;
    HighLevelControl::aluOperation      AluOperation_R;
    HighLevelControl::computeSrc        ComputeSrc_R;

    //M
    logic                               MemEn_R, MemWriteEn_R;
    HighLevelControl::storeType         StoreType_R;

    //W
    logic                               RegWrite_R;
    HighLevelControl::resultSrc         ResultSrc_R;
    HighLevelControl::truncType         TruncType_R;

                        ////****C Stage****////
    logic[`XLEN-1:0]                    Passthrough_C, AluOperandA_C, AluOperandB_C, AluResult_C, ComputeResult_C, MemWriteData_C;
    logic[$clog2(`WORD_SIZE)-1:0]       rd1Adr_C;
    logic[`XLEN-1:0]                    AluHazzardSafeOperandA_C, AluHazzardSafeOperandB_C;

    HighLevelControl::pcSrc             PCSrcPostConditional_C;

    //Controller Signals
    HighLevelControl::pcSrc             PCSrc_C;
    HighLevelControl::conditionalPCSrc  ConditionalPCSrc_C;

    logic                               AluOperandBForwardEn_C;
    HighLevelControl::aluOperation      AluOperation_C;
    HighLevelControl::computeSrc        ComputeSrc_C;

    //M
    logic                               MemEn_C, MemWriteEn_C;
    logic[`XLEN-1:0]                    DataMemAdr_C;
    HighLevelControl::storeType         StoreType_C;
    logic[(`XLEN/8)-1:0]                MemWriteByteEn_C;

    //W
    logic                               RegWrite_C;
    HighLevelControl::resultSrc         ResultSrc_C;
    HighLevelControl::truncType         TruncType_C;

    //ALU Flags
    logic                               Zero_C, oVerflow_C, Carry_C, Negative_C;

                        ////****M Stage****////
    logic[`XLEN-1:0]                    ComputeResult_M, MemWriteData_M, MemReadData_M;
    logic[$clog2(`WORD_SIZE)-1:0]       rd1Adr_M;

    //Controller Signals
    logic                               MemEn_M, MemWriteEn_M;
    logic[(`XLEN/8)-1:0]                MemWriteByteEn_M;

    //W
    logic                               RegWrite_M;
    HighLevelControl::resultSrc         ResultSrc_M;
    HighLevelControl::truncType         TruncType_M;
    logic[$clog2(`XLEN/8)-1:0]           TruncSrc_M;

                        ////****W Stage****////
    logic[`XLEN-1:0]                    Rd1_W, Result_W, ComputeResult_W, MemReadData_W;
    logic[$clog2(`WORD_SIZE)-1:0]       rd1Adr_W;

    //Controller Signals
    logic                               RegWrite_W;
    HighLevelControl::resultSrc         ResultSrc_W;
    HighLevelControl::truncType         TruncType_W;
    logic[$clog2(`XLEN/8)-1:0]           TruncSrc_W;

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

    logic [`XLEN-1:0] PROGRAM_ENTRY_ADR;
    initial begin
        PROGRAM_ENTRY_ADR = '0; // default
        void'($value$plusargs("ENTRY_ADDR=%h", PROGRAM_ENTRY_ADR)); // override if provided
        $display("[TB] ENTRY_ADDR = 0x%h", PROGRAM_ENTRY_ADR);
    end

    //Program Counter
    `ifdef PIPELINED
        always_ff @( posedge clk ) begin
            if (reset)          PC_I <= PROGRAM_ENTRY_ADR;
            else if (~StallPC)  PC_I <= PCNext_I;
        end
    `else
        always_ff @( posedge clk ) begin
            if (reset)  PC_I <= PROGRAM_ENTRY_ADR;
            else        PC_I <= PCNext_I;
        end
    `endif

    assign PCp4_I       = PC_I + 4;

    //****Instruction cache controlled externally****//
    assign External_PC  = PC_I;
    assign Instr_I      = External_Instr;

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

    `else
        assign Instr_R  = Instr_I;
        assign PC_R     = PC_I;
        assign PCp4_R   = PCp4_I;
    `endif

    ////                        **** R STAGE ****                       ////

    //Bus assignments
    assign rs1Adr_R     = Instr_R[19:15];
    assign rs2Adr_R     = Instr_R[24:20];
    assign rd1Adr_R     = Instr_R[11:7];

    //Controller
    controller Controller(.Instr_R,
        .PCSrc_R, .ConditionalPCSrc_R, .RegWrite_R, .ImmSrc_R, .PassthroughSrc_R, .AluSrcB_R,
        .AluOperation_R, .ComputeSrc_R, .MemEn_R, .MemWriteEn_R, .StoreType_R, .ResultSrc_R, .TruncType_R);

    //Register File
    registerFile #(.REGISTER_COUNT(`WORD_SIZE)) RegisterFile(
        .clk, .reset, .WriteEn(RegWrite_W), .rs1Adr(rs1Adr_R), .rs2Adr(rs2Adr_R),
        .rd1Adr(rd1Adr_W), .Rd1(Rd1_W), .Rs1(Rs1_R), .Rs2(Rs2_R)
    );

    //ALU Src A Mux
    assign AluOperandA_R = Rs1_R;

    //ALU Src B Mux
    always_comb begin
        casex(AluSrcB_R)
            HighLevelControl::Rs2:  AluOperandB_R = Rs2_R;
            HighLevelControl::Imm:  AluOperandB_R = Imm_R;
            default:                AluOperandB_R = 'x;
        endcase
    end

    assign AluOperandBForwardEn_R = AluSrcB_R == HighLevelControl::Rs2;

    //Immediate Extender
    immediateExtender ImmediateExtender(.ImmSrc(ImmSrc_R), .Instr(Instr_R), .Imm(Imm_R));

    //Jump / Branch Adder
    assign PCpImm_R = Imm_R + PC_R;

    //Passthrough Mux
    always_comb begin
        casex(PassthroughSrc_R)
            HighLevelControl::PCpImm:       Passthrough_R = PCpImm_R;
            HighLevelControl::PCp4:         Passthrough_R = PCp4_R;
            HighLevelControl::WriteData:    Passthrough_R = Rs2_R;
            HighLevelControl::LoadImm:      Passthrough_R = Imm_R;

            default:                        Passthrough_R = 'x;
        endcase
    end

    `ifdef PIPELINED

        //Data
        flopRS #(.WIDTH(`XLEN * 3 + $clog2(`WORD_SIZE))) DataFlopRC(.clk, .reset, .stall(StallRC),
                .D({AluOperandA_R, AluOperandB_R, Passthrough_R, rd1Adr_R}),
                .Q({AluOperandA_C, AluOperandB_C, Passthrough_C, rd1Adr_C})
            );

        //Signals
        flopRS #(.WIDTH(
            $bits({PCSrc_R, ConditionalPCSrc_R, AluOperandBForwardEn_R, AluOperation_R,
                    ComputeSrc_R, ResultSrc_R, TruncType_R})
        )) SignalFlopRC(.clk, .reset, .stall(StallRC),
                .D({PCSrc_R, ConditionalPCSrc_R, AluOperandBForwardEn_R, AluOperation_R,
                    ComputeSrc_R, ResultSrc_R, TruncType_R}),
                .Q({PCSrc_C, ConditionalPCSrc_C, AluOperandBForwardEn_C, AluOperation_C,
                    ComputeSrc_C, ResultSrc_C, TruncType_C})
            );

        //Archetectural Signals
        flopRFS #(.WIDTH(
            $bits({MemEn_R, MemWriteEn_R, StoreType_R, RegWrite_R})
        )) ArchetecturalSignalFlopRC(.clk, .reset, .stall(StallRC), .flush(FlushRC),
                .D({MemEn_R, MemWriteEn_R, StoreType_R, RegWrite_R}),
                .Q({MemEn_C, MemWriteEn_C, StoreType_C, RegWrite_C})
            );

    `else

        //Data
        assign AluOperandA_C            = AluOperandA_R;
        assign AluOperandB_C            = AluOperandB_R;
        assign Passthrough_C            = Passthrough_R;
        assign rd1Adr_C                 = rd1Adr_R;

        //Signals
        assign PCSrc_C                  = PCSrc_R;
        assign ConditionalPCSrc_C       = ConditionalPCSrc_R;
        assign AluOperandBForwardEn_C   = AluOperandBForwardEn_R;
        assign AluOperation_C           = AluOperation_R;
        assign ComputeSrc_C             = ComputeSrc_R;
        assign MemEn_C                  = MemEn_R;
        assign MemWriteEn_C             = MemWriteEn_R;
        assign StoreType_C              = StoreType_R;
        assign ResultSrc_C              = ResultSrc_R;
        assign RegWrite_C               = RegWrite_R;
        assign TruncType_C              = TruncType_R;

    `endif

    ////                        **** C STAGE ****                       ////

    `ifdef PIPELINED

        //Forward Muxes
        always_comb begin

            casex(Rs1ForwardSrc_C)
                HighLevelControl::Rs1_NO_FORWARD:       AluHazzardSafeOperandA_C = AluOperandA_C;
                HighLevelControl::Rs1_ComputeResult:    AluHazzardSafeOperandA_C = ComputeResult_M;
                HighLevelControl::Rs1_Rd1W:             AluHazzardSafeOperandA_C = Rd1_W;
                HighLevelControl::Rs1_Rd1PostW:         AluHazzardSafeOperandA_C = Rd1_PostW;

                default:                                AluHazzardSafeOperandA_C = 'x;
            endcase

        end

        always_comb begin

            AluHazzardSafeOperandB_C = AluOperandB_C;

            if(AluOperandBForwardEn_C) begin
                casex(Rs2ForwardSrc_C)
                    HighLevelControl::Rs2_NO_FORWARD:       AluHazzardSafeOperandB_C = AluOperandB_C;
                    HighLevelControl::Rs2_ComputeResult:    AluHazzardSafeOperandB_C = ComputeResult_M;
                    HighLevelControl::Rs2_Rd1W:             AluHazzardSafeOperandB_C = Rd1_W;
                    HighLevelControl::Rs2_Rd1PostW:         AluHazzardSafeOperandB_C = Rd1_PostW;

                    default:                                AluHazzardSafeOperandB_C = 'x;
                endcase
            end
        end

    `else

        assign AluHazzardSafeOperandA_C = AluOperandA_C;
        assign AluHazzardSafeOperandB_C = AluOperandB_C;

    `endif

    //ALU
    behavioralAlu ALU(.AluOperation(AluOperation_C), .AluOperandA(AluHazzardSafeOperandA_C), .AluOperandB(AluHazzardSafeOperandB_C),
                    .Zero(Zero_C), .oVerflow(oVerflow_C), .Negative(Negative_C), .Carry(Carry_C), .AluResult(AluResult_C));

    branchHandler BranchHandler(.PCSrc_C, .ConditionalPCSrc_C,
            .Zero_C, .Carry_C, .Negative_C, .oVerflow_C, .PCSrcPostConditional_C);

    //Compute Result Select Mux
    always_comb begin
        casex(ComputeSrc_C)
            HighLevelControl::ALU:          ComputeResult_C = AluResult_C;
            HighLevelControl::Passthrough:  ComputeResult_C = Passthrough_C;

            default:                        ComputeResult_C = 'x;

        endcase
    end

    assign DataMemAdr_C = ComputeResult_C;

    // Determine Mem byte en bits

    always_comb begin
        localparam int BYTE_OFFSET_BITS = $clog2(`XLEN/8);
        logic[BYTE_OFFSET_BITS-1:0]    ByteOffset;
        logic misaligned;

        ByteOffset              = DataMemAdr_C[BYTE_OFFSET_BITS-1:0];
        MemWriteByteEn_C        = '0;

        case (StoreType_C)
            HighLevelControl::Store_Half_Word:    misaligned  = DataMemAdr_C[0];      // halfword: bit0 must be 0
            HighLevelControl::Store_Word:         misaligned  = |DataMemAdr_C[1:0];   // word: low 2 bits must be 0 (for 32-bit word)
            `ifdef XLEN_64
            HighLevelControl::Store_Double_Word:  misaligned  = |DataMemAdr_C[2:0];   // dword: low 3 bits must be 0
            `endif
            default:            misaligned = 1'b0;
        endcase

        if (misaligned) begin
            MemWriteByteEn_C = 'x;   // and raise/store-misaligned exception elsewhere
        end else begin
            case(StoreType_C)
                HighLevelControl::Store_Byte:           MemWriteByteEn_C[ByteOffset+0 -: 1] = 1'b1;
                HighLevelControl::Store_Half_Word:      MemWriteByteEn_C[ByteOffset+1 -: 2] = 2'b11;
                HighLevelControl::Store_Word:           MemWriteByteEn_C[ByteOffset+3 -: 4] = 4'b1111;
                `ifdef XLEN_64
                HighLevelControl::Store_Double_Word:    MemWriteByteEn_C[ByteOffset+7 -: 8] = 8'hFF;
                `endif
                default:                                MemWriteByteEn_C                  = 'x;
            endcase
        end
    end


    // Hazzards

    `ifdef PIPELINED

        //Forward Mux
        always_comb begin

            casex(Rs2ForwardSrc_C)
                HighLevelControl::Rs2_NO_FORWARD:       MemWriteData_C = Passthrough_C;
                HighLevelControl::Rs2_ComputeResult:    MemWriteData_C = ComputeResult_M;
                HighLevelControl::Rs2_Rd1W:             MemWriteData_C = Rd1_W;
                HighLevelControl::Rs2_Rd1PostW:         MemWriteData_C = Rd1_PostW;

                default:                                MemWriteData_C = 'x;
            endcase

        end

    `else

        assign MemWriteData_C = Passthrough_C;

    `endif

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

        //Archetectural Signals
        flopRF #(.WIDTH(
            $bits({MemEn_C, MemWriteEn_C, MemWriteByteEn_C, RegWrite_C})
        )) ArchetecturalSignalFlopCM(.clk, .reset, .flush(FlushCM),
                .D({MemEn_C, MemWriteEn_C, MemWriteByteEn_C, RegWrite_C}),
                .Q({MemEn_M, MemWriteEn_M, MemWriteByteEn_M, RegWrite_M})
        );

    `else

        //Data
        assign ComputeResult_M  = ComputeResult_C;
        assign MemWriteData_M   = MemWriteData_C;
        assign rd1Adr_M         = rd1Adr_C;

        //Signals
        assign MemEn_M          = MemEn_C;
        assign MemWriteEn_M     = MemWriteEn_C;
        assign MemWriteByteEn_M = MemWriteByteEn_C;
        assign ResultSrc_M      = ResultSrc_C;
        assign RegWrite_M       = RegWrite_C;
        assign TruncType_M      = TruncType_C;

    `endif

    ////                        **** M STAGE ****                       ////

    ////Memory Cache handled externally////
    assign External_MemEn           = MemEn_M;
    assign External_MemWriteEn      = MemWriteEn_M;
    assign External_MemAdr          = {ComputeResult_M[`XLEN-1 : $clog2(`XLEN/8)], {($clog2(`XLEN/8)) {1'b0}}};
    assign External_MemWriteData    = MemWriteData_M;
    assign External_MemWriteByteEn  = MemWriteByteEn_M;

    assign MemReadData_M            = External_MemReadData;


    assign TruncSrc_M               = ComputeResult_M[$clog2(`XLEN/8)-1 : 0];

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

        //Archetectural Signals
        flopR #(.WIDTH(
            $bits({RegWrite_M})
        )) ArchetecturalSignalFlopMW(.clk, .reset,
                .D({RegWrite_M}),
                .Q({RegWrite_W})
        );

    `else

        //Data
        assign ComputeResult_W  = ComputeResult_M;
        assign MemReadData_W    = MemReadData_M;
        assign rd1Adr_W         = rd1Adr_M;

        //Signals
        assign RegWrite_W       = RegWrite_M;
        assign ResultSrc_W      = ResultSrc_M;
        assign TruncType_W      = TruncType_M;
        assign TruncSrc_W       = TruncSrc_M;

    `endif

    ////                        **** W STAGE ****                       ////

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

        // assign Rs1ForwardSrc_C        = HighLevelControl::Rs1_NO_FORWARD;
        // assign Rs2ForwardSrc_C        = HighLevelControl::Rs2_NO_FORWARD;

        // assign FlushCM              = 1'b0;
        // assign StallPC              = 1'b0;
        // assign StallIR              = 1'b0;
        // assign StallRC              = 1'b0;
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

        logic[$clog2(`WORD_SIZE)-1:0]   rs1Adr_C, rs2Adr_C;
        logic[`XLEN-1:0]           Rs1_C, Rs2_C, Imm_C;

        logic[$clog2(`WORD_SIZE)-1:0]   rs1Adr_M, rs2Adr_M;
        logic[`XLEN-1:0]           Rs1_M, Rs2_M, Imm_M, AluHazzardSafeOperandA_M, AluHazzardSafeOperandB_M;
        HighLevelControl::aluOperation  AluOperation_M;

        logic[$clog2(`WORD_SIZE)-1:0]   rs1Adr_W, rs2Adr_W;
        logic[`XLEN-1:0]           Rs1_W, Rs2_W, Imm_W, AluHazzardSafeOperandA_W, AluHazzardSafeOperandB_W, MemWriteData_W;
        HighLevelControl::aluOperation  AluOperation_W;

        flopR #(`XLEN * 3 + $clog2(`WORD_SIZE) * 2) DebugFlopRC (.clk, .reset,
            .D({rs1Adr_R, rs2Adr_R, Rs1_R, Rs2_R, Imm_R}),
            .Q({rs1Adr_C, rs2Adr_C, Rs1_C, Rs2_C, Imm_C})
            );

        flopR #(`XLEN * 5 + $clog2(`WORD_SIZE) * 2 + $bits(AluOperation_M)) DebugFlopCM (.clk, .reset,
            .D({rs1Adr_C, rs2Adr_C, Rs1_C, Rs2_C, Imm_C, AluHazzardSafeOperandA_C, AluHazzardSafeOperandB_C, AluOperation_C}),
            .Q({rs1Adr_M, rs2Adr_M, Rs1_M, Rs2_M, Imm_M, AluHazzardSafeOperandA_M, AluHazzardSafeOperandB_M, AluOperation_M})
            );

        flopR #(`XLEN * 6 + $clog2(`WORD_SIZE) * 2 + $bits(AluOperation_W)) DebugFlopMW (.clk, .reset,
            .D({rs1Adr_M, rs2Adr_M, Rs1_M, Rs2_M, Imm_M, AluHazzardSafeOperandA_M, AluHazzardSafeOperandB_M, MemWriteData_M, AluOperation_M}),
            .Q({rs1Adr_W, rs2Adr_W, Rs1_W, Rs2_W, Imm_W, AluHazzardSafeOperandA_W, AluHazzardSafeOperandB_W, MemWriteData_W, AluOperation_W})
            );

    `endif

endmodule
