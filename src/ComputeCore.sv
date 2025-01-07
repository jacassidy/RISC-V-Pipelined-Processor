//James Kaden Cassidy jkc.cassidy@gmail.com 12/19/2024

`include "parameters.svh"

module computeCore #(

) (
    input   logic                       clk,
    input   logic                       reset,

    //To handle memory / chache externally
    output  logic[`BIT_COUNT-1:0]       External_PC,       //Instruction Cache

    output  logic                       External_MemEn,
    output  logic                       External_MemWriteEn,       //Command Memory to write
    output  logic[(`BIT_COUNT/8)-1:0]   External_MemByteEn,         //Bytes to be writen
    output  logic[`BIT_COUNT-1:0]       External_MemAdr,         //Memory Adress
    output  logic[`BIT_COUNT-1:0]       External_MemWriteData,   //Memory to be saved

    input   logic[`WORD_SIZE-1:0]       External_Instr,
    input   logic[`BIT_COUNT-1:0]       External_MemReadData
);

    

                        ////****I Stage****////
    logic[`BIT_COUNT-1:0]               PCNext_I, PCp4_I, PC_I;
    logic[`WORD_SIZE-1:0]               Instr_I;

                        ////****R Stage****////
    logic[`WORD_SIZE-1:0]               Instr_R;
    logic[`BIT_COUNT-1:0]               PCp4_R, PC_R, Rs1_R, Rs2_R, Imm_R, PCpImm_R, Passthrough_R;
    logic[$clog2(`WORD_SIZE)-1:0]       rs1Adr_R, rs2Adr_R;
    logic[$clog2(`WORD_SIZE)-1:0]       rd1Adr_R;

    //Controller Signals
    HighLevelControl::immSrc            ImmSrc_R;
    HighLevelControl::aluSrcB           AluSrcB_R;
    HighLevelControl::passthroughSrc           PassthroughSrc_R;
    HighLevelControl::pcSrc             PCSrc_R;

    //C
    logic[`BIT_COUNT-1:0]               AluOperandA_R, AluOperandB_R;
    HighLevelControl::conditionalPCSrc  ConditionalPCSrc_R;

    logic                               AluOperandBForwardEn_R;
    HighLevelControl::aluOperation      AluOperation_R;
    HighLevelControl::computeSrc        ComputeSrc_R;

    //M
    logic                               MemEn_R, MemWriteEn_R;
    logic[(`BIT_COUNT/8)-1:0]           MemByteEn_R;
    
    //W
    logic                               RegWrite_R;
    HighLevelControl::resultSrc         ResultSrc_R;
    HighLevelControl::truncSrc          TruncSrc_R;

                        ////****C Stage****////
    logic[`BIT_COUNT-1:0]               Passthrough_C, AluOperandA_C, AluOperandB_C, AluResult_C, ComputeResult_C, MemWriteData_C;
    logic[$clog2(`WORD_SIZE)-1:0]       rd1Adr_C;
    logic[`BIT_COUNT-1:0]               AluHazzardSafeOperandA_C, AluHazzardSafeOperandB_C;

    HighLevelControl::pcSrc             PCSrcPostConditional_C;

    //Controller Signals
    HighLevelControl::pcSrc             PCSrc_C;
    HighLevelControl::conditionalPCSrc  ConditionalPCSrc_C;

    logic                               AluOperandBForwardEn_C;
    HighLevelControl::aluOperation      AluOperation_C;
    HighLevelControl::computeSrc        ComputeSrc_C;

    //M
    logic                               MemEn_C, MemWriteEn_C;
    logic[(`BIT_COUNT/8)-1:0]           MemByteEn_C;

    //W
    logic                               RegWrite_C;
    HighLevelControl::resultSrc         ResultSrc_C;
    HighLevelControl::truncSrc          TruncSrc_C;

    //ALU Flags
    logic                               Zero_C, oVerflow_C, Carry_C, Negative_C;

                        ////****M Stage****////
    logic[`BIT_COUNT-1:0]               ComputeResult_M, MemWriteData_M, MemReadData_M;
    logic[$clog2(`WORD_SIZE)-1:0]       rd1Adr_M;

    //Controller Signals
    logic                               MemEn_M, MemWriteEn_M;
    logic[(`BIT_COUNT/8)-1:0]           MemByteEn_M;

    //W
    logic                               RegWrite_M;
    HighLevelControl::resultSrc         ResultSrc_M;
    HighLevelControl::truncSrc          TruncSrc_M;

                        ////****W Stage****////
    logic[`BIT_COUNT-1:0]               Rd1_W, Result_W, ComputeResult_W, MemReadData_W;  
    logic[$clog2(`WORD_SIZE)-1:0]       rd1Adr_W;

    //Controller Signals
    logic                               RegWrite_W;
    HighLevelControl::resultSrc         ResultSrc_W;
    HighLevelControl::truncSrc          TruncSrc_W;

                        ////****HAZZARDS****////
    `ifdef PIPELINED                    
        HighLevelControl::rs1ForwardSrc     Rs1ForwardSrc;
        HighLevelControl::rs2ForwardSrc     Rs2ForwardSrc;

        logic                               FlushIR, FlushRC, FlushCM;
        logic                               StallPC, StallIR, StallRC;
    `endif

    ////                        **** I STAGE ****                       ////

    //Program Counter
    `ifdef PIPELINED
        flopRS #(.WIDTH(`BIT_COUNT)) ProgramCounter(.clk, .reset, .stall(StallPC), .D(PCNext_I), .Q(PC_I));
    `else
        flopR #(.WIDTH(`BIT_COUNT)) ProgramCounter(.clk, .reset, .D(PCNext_I), .Q(PC_I));
    `endif 

    assign PCp4_I       = PC_I + 4;

    //****Instuction cache controlled externally****//
    assign External_PC  = PC_I;
    assign Instr_I      = External_Instr;

    //Pipeline Registers
    `ifdef PIPELINED

        //Data
        flopRS #(.WIDTH(`BIT_COUNT * 2)) DataFlopIR(.clk, .reset, .stall(StallIR),
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
        .AluOperation_R, .ComputeSrc_R, .MemEn_R, .MemWriteEn_R, .MemByteEn_R, .ResultSrc_R, .TruncSrc_R);

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
        flopRS #(.WIDTH(`BIT_COUNT * 3 + $clog2(`WORD_SIZE))) DataFlopRC(.clk, .reset, .stall(StallRC),
                .D({AluOperandA_R, AluOperandB_R, Passthrough_R, rd1Adr_R}), 
                .Q({AluOperandA_C, AluOperandB_C, Passthrough_C, rd1Adr_C})
            );

        //Signals
        flopRS #(.WIDTH(
            $bits({PCSrc_R, ConditionalPCSrc_R, AluOperandBForwardEn_R, AluOperation_R,
                    ComputeSrc_R, ResultSrc_R, TruncSrc_R})
        )) SignalFlopRC(.clk, .reset, .stall(StallRC),
                .D({PCSrc_R, ConditionalPCSrc_R, AluOperandBForwardEn_R, AluOperation_R,
                    ComputeSrc_R, ResultSrc_R, TruncSrc_R}), 
                .Q({PCSrc_C, ConditionalPCSrc_C, AluOperandBForwardEn_C, AluOperation_C,
                    ComputeSrc_C, ResultSrc_C, TruncSrc_C})
            );

        //Archetectural Signals
        flopRFS #(.WIDTH(
            $bits({MemEn_R, MemWriteEn_R, MemByteEn_R, RegWrite_R})
        )) ArchetecturalSignalFlopRC(.clk, .reset, .stall(StallRC), .flush(FlushRC),
                .D({MemEn_R, MemWriteEn_R, MemByteEn_R, RegWrite_R}), 
                .Q({MemEn_C, MemWriteEn_C, MemByteEn_C, RegWrite_C})
            );
            
    `else

        //Data
        assign AluOperandA_C            = AluOperandA_R;
        assign AluOperandB_C            = AluOperandB_R;
        assign Passthrough_C                   = Passthrough_R;
        assign rd1Adr_C                 = rd1Adr_R;

        //Signals
        assign PCSrc_C                  = PCSrc_R;
        assign ConditionalPCSrc_C       = ConditionalPCSrc_R;
        assign AluOperandBForwardEn_C   = AluOperandBForwardEn_R;
        assign AluOperation_C           = AluOperation_R;
        assign ComputeSrc_C             = ComputeSrc_R;
        assign MemEn_C                  = MemEn_R;
        assign MemWriteEn_C             = MemWriteEn_R;
        assign MemByteEn_C              = MemByteEn_R;
        assign ResultSrc_C              = ResultSrc_R;
        assign RegWrite_C               = RegWrite_R;
        assign TruncSrc_C               = TruncSrc_R;

    `endif

    ////                        **** C STAGE ****                       ////

    `ifdef PIPELINED

        //Forward Muxes
        always_comb begin
            
            casex(Rs1ForwardSrc)
                HighLevelControl::Rs1_NO_FORWARD:       AluHazzardSafeOperandA_C = AluOperandA_C;
                HighLevelControl::Rs1_COMPUTE_RESULT:   AluHazzardSafeOperandA_C = ComputeResult_M;
                HighLevelControl::Rs1_TRUNCATED_RESULT: AluHazzardSafeOperandA_C = Rd1_W;

                default:                                AluHazzardSafeOperandA_C = 'x;
            endcase

        end

        always_comb begin

            AluHazzardSafeOperandB_C = AluOperandB_C;

            if(AluOperandBForwardEn_C) begin
                casex(Rs2ForwardSrc)
                    HighLevelControl::Rs2_NO_FORWARD:       AluHazzardSafeOperandB_C = AluOperandB_C;
                    HighLevelControl::Rs2_COMPUTE_RESULT:   AluHazzardSafeOperandB_C = ComputeResult_M;
                    HighLevelControl::Rs2_TRUNCATED_RESULT: AluHazzardSafeOperandB_C = Rd1_W;

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
            HighLevelControl::Passthrough:         ComputeResult_C = Passthrough_C;

            default:                        ComputeResult_C = 'x;

        endcase
    end

    //
    

    `ifdef PIPELINED

        //Forward Mux
        always_comb begin
            
            casex(Rs2ForwardSrc)
                HighLevelControl::Rs2_NO_FORWARD:       MemWriteData_C = Passthrough_C;
                HighLevelControl::Rs2_COMPUTE_RESULT:   MemWriteData_C = ComputeResult_M;
                HighLevelControl::Rs2_TRUNCATED_RESULT: MemWriteData_C = Rd1_W;

                default:                                MemWriteData_C = 'x;
            endcase

        end

    `else

        assign MemWriteData_C = Passthrough_C;

    `endif

    `ifdef PIPELINED

        //Data
        flopR #(.WIDTH(`BIT_COUNT * 2 + $clog2(`WORD_SIZE))) DataFlopCM(.clk, .reset, 
                .D({ComputeResult_C, MemWriteData_C, rd1Adr_C}), 
                .Q({ComputeResult_M, MemWriteData_M, rd1Adr_M})
            );

        //Signals
        flopR #(.WIDTH(
            $bits({ResultSrc_C, TruncSrc_C})
        )) SignalFlopCM(.clk, .reset, 
                .D({ResultSrc_C, TruncSrc_C}), 
                .Q({ResultSrc_M, TruncSrc_M})
        );

        //Archetectural Signals
        flopRF #(.WIDTH(
            $bits({MemEn_C, MemWriteEn_C, MemByteEn_C, RegWrite_C})
        )) ArchetecturalSignalFlopCM(.clk, .reset, .flush(FlushCM),
                .D({MemEn_C, MemWriteEn_C, MemByteEn_C, RegWrite_C}), 
                .Q({MemEn_M, MemWriteEn_M, MemByteEn_M, RegWrite_M})
        );
        
    `else

        //Data
        assign ComputeResult_M  = ComputeResult_C;
        assign MemWriteData_M   = MemWriteData_C;
        assign rd1Adr_M         = rd1Adr_C;

        //Signals
        assign MemEn_M          = MemEn_C;
        assign MemWriteEn_M     = MemWriteEn_C;
        assign MemByteEn_M      = MemByteEn_C;
        assign ResultSrc_M      = ResultSrc_C;
        assign RegWrite_M       = RegWrite_C;
        assign TruncSrc_M       = TruncSrc_C;

    `endif

    ////                        **** M STAGE ****                       ////

    ////Memory Cache handled externally////
    assign External_MemEn           = MemEn_M;
    assign External_MemWriteEn      = MemWriteEn_M;
    assign External_MemAdr          = ComputeResult_M;
    assign External_MemWriteData    = MemWriteData_M;
    assign External_MemByteEn       = MemByteEn_M;

    assign MemReadData_M            = External_MemReadData;


    `ifdef PIPELINED

        //Data
        flopR #(.WIDTH(2 * `BIT_COUNT + $clog2(`WORD_SIZE))) DataFlopMW(.clk, .reset, 
                .D({ComputeResult_M, MemReadData_M, rd1Adr_M}), 
                .Q({ComputeResult_W, MemReadData_W, rd1Adr_W})
            );

        //Signals
        flopR #(.WIDTH(
            $bits({ResultSrc_M, TruncSrc_M})
        )) SignalFlopMW(.clk, .reset, 
                .D({ResultSrc_M, TruncSrc_M}), 
                .Q({ResultSrc_W, TruncSrc_W})
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
    truncator Truncator(.TruncSrc(TruncSrc_W), .Input(Result_W), .TruncResult(Rd1_W));

    ////                        **** HAZZARDS ****                       ////
    logic PredictionCorrect_C;
    
    `ifdef PIPELINED
        //Prediction is only ever correct when there was a branch and it is not taken
        assign PredictionCorrect_C = PCSrcPostConditional_C != HighLevelControl::Branch_C && ConditionalPCSrc_C != HighLevelControl::NO_BRANCH;

        hazzardUnit HazzardUnit(.clk, .reset, .rs1Adr_R, .rs2Adr_R, .rd1Adr_C, .rd1Adr_M, .MemEn_C, .RegWrite_C, .RegWrite_M, 
                                .Rs1ForwardSrc, .Rs2ForwardSrc, .FlushCM, .StallPC, .StallIR, .StallRC);

    `else
        assign PredictionCorrect_C  = 1'b0;

        // assign Rs1ForwardSrc        = HighLevelControl::Rs1_NO_FORWARD;
        // assign Rs2ForwardSrc        = HighLevelControl::Rs2_NO_FORWARD;

        // assign FlushCM              = 1'b0;
        // assign StallPC              = 1'b0;
        // assign StallIR              = 1'b0;
        // assign StallRC              = 1'b0;
    `endif

    //PC Source Select Mux implemented with branch prediction
    pcUpdateHandler PCUpdateHandler(.PCSrc_R(PCSrc_R), 
            .PCSrcPostConditional_C, .Predict(1'b0), .Prediction(`BIT_COUNT'b0), .PredictionCorrect_R(1'b0), 
            .PredictionCorrect_C, .PCp4_I, .AluAdd_C(AluResult_C), .PCpImm_R, .UpdatedPC_C(Passthrough_C), .PCNext_I
            
            `ifdef PIPELINED
                , .FlushIR, .FlushRC
            `endif 
            
            );

    `ifdef DEBUGGING

        logic[$clog2(`WORD_SIZE)-1:0]   rs1Adr_C, rs2Adr_C;
        logic[`BIT_COUNT-1:0]           Rs1_C, Rs2_C, Imm_C;

        logic[$clog2(`WORD_SIZE)-1:0]   rs1Adr_M, rs2Adr_M;
        logic[`BIT_COUNT-1:0]           Rs1_M, Rs2_M, Imm_M, AluHazzardSafeOperandA_M, AluHazzardSafeOperandB_M;
        HighLevelControl::aluOperation  AluOperation_M;

        logic[$clog2(`WORD_SIZE)-1:0]   rs1Adr_W, rs2Adr_W;
        logic[`BIT_COUNT-1:0]           Rs1_W, Rs2_W, Imm_W, AluHazzardSafeOperandA_W, AluHazzardSafeOperandB_W, MemWriteData_W;
        HighLevelControl::aluOperation  AluOperation_W;

        flopR #(`BIT_COUNT * 3 + $clog2(`WORD_SIZE) * 2) DebugFlopRC (.clk, .reset,
            .D({rs1Adr_R, rs2Adr_R, Rs1_R, Rs2_R, Imm_R}),
            .Q({rs1Adr_C, rs2Adr_C, Rs1_C, Rs2_C, Imm_C})
            );

        flopR #(`BIT_COUNT * 5 + $clog2(`WORD_SIZE) * 2 + $bits(AluOperation_M)) DebugFlopCM (.clk, .reset,
            .D({rs1Adr_C, rs2Adr_C, Rs1_C, Rs2_C, Imm_C, AluHazzardSafeOperandA_C, AluHazzardSafeOperandB_C, AluOperation_C}),
            .Q({rs1Adr_M, rs2Adr_M, Rs1_M, Rs2_M, Imm_M, AluHazzardSafeOperandA_M, AluHazzardSafeOperandB_M, AluOperation_M})
            );
            
        flopR #(`BIT_COUNT * 6 + $clog2(`WORD_SIZE) * 2 + $bits(AluOperation_W)) DebugFlopMW (.clk, .reset,
            .D({rs1Adr_M, rs2Adr_M, Rs1_M, Rs2_M, Imm_M, AluHazzardSafeOperandA_M, AluHazzardSafeOperandB_M, MemWriteData_M, AluOperation_M}),
            .Q({rs1Adr_W, rs2Adr_W, Rs1_W, Rs2_W, Imm_W, AluHazzardSafeOperandA_W, AluHazzardSafeOperandB_W, MemWriteData_W, AluOperation_W})
            );

    `endif

endmodule