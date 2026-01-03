//James Kaden Cassidy jkc.cassidy@gmail.com 1/2/2026

`include "parameters.svh"

module _CStage (
    input  logic                          clk,
    input  logic                          reset,

    // From RC pipeline regs (in computeCore)
    input  logic                          ValidInstruction_C,

    input  logic [`XLEN-1:0]              Passthrough_C,
    input  logic [`XLEN-1:0]              AluOperandA_C,
    input  logic [`XLEN-1:0]              AluOperandB_C,
    input  logic [$clog2(`WORD_SIZE)-1:0]  rd1Adr_C,

    input  HighLevelControl::pcSrc         PCSrc_C,
    input  HighLevelControl::conditionalPCSrc ConditionalPCSrc_C,

    input  logic                          AluOperandAForwardEn_C,
    input  logic                          AluOperandBForwardEn_C,
    input  HighLevelControl::aluOperation  AluOperation_C,
    input  HighLevelControl::computeSrc    ComputeSrc_C,

    input  logic                          MemEn_C,
    input  logic                          MemWriteEn_C,
    input  HighLevelControl::storeType     StoreType_C,

    input  logic                          RegWrite_C,
    input  HighLevelControl::resultSrc     ResultSrc_C,
    input  HighLevelControl::truncType     TruncType_C,

`ifdef ZICSR
    input  logic                          CSREn_C,
    input  HighLevelControl::csrOp        CSROp_C,
`endif

`ifdef PIPELINED
    // Forwarding select + values (from hazard unit / later stages)
    input  HighLevelControl::rs1ForwardSrc Rs1ForwardSrc_C,
    input  HighLevelControl::rs2ForwardSrc Rs2ForwardSrc_C,
    input  logic [`XLEN-1:0]              ComputeResult_M,  // from CM regs output (registered)
    input  logic [`XLEN-1:0]              Rd1_W,            // from WStage output
    input  logic [`XLEN-1:0]              Rd1_PostW,        // from postW flop in computeCore
`endif

`ifdef ZICNTR
    input  logic                          ValidInstruction_W,
`endif

    // Taps used by pcUpdateHandler / hazard logic
    output logic [`XLEN-1:0]              AluResult_C,
    output HighLevelControl::pcSrc        PCSrcPostConditional_C,

    // === Outputs that feed CM pipeline regs (kept in computeCore) ===
    output logic [`XLEN-1:0]              ComputeResult_C,
    output logic [`XLEN-1:0]              MemWriteData_C,
    output logic [(`XLEN/8)-1:0]          MemWriteByteEn_C
);

    //ALU Flags
    logic                                   Zero_C, oVerflow_C, Carry_C, Negative_C;

    logic[`XLEN-1:0]                        AluHazzardSafeOperandA_C, AluHazzardSafeOperandB_C;
    logic[$clog2(`XLEN/8)-1:0]              DataMemAdrByteOffset_C;

    `ifdef ZICNTR
    wire ZICSRType::csrCtrl                 csr_control [(1 << $clog2(ZICSRType::CSR_COUNT))-1:0];
    wire logic[`XLEN-1:0]                   csr_values  [(1 << $clog2(ZICSRType::CSR_COUNT))-1:0];

    logic[`XLEN-1:0]                        CSRReadValue_C;
    logic                                   CSRAdrValid_C;
    logic[$clog2(`CSR_ADDRESS_SPACE)-1:0]   CSRAdr_C;
    `endif

    logic[`XLEN-1:0]                        MemWriteDataPreShift_C;

    `ifdef PIPELINED

        //Forward Muxes
        always_comb begin

            AluHazzardSafeOperandA_C = AluOperandA_C;

            if(AluOperandAForwardEn_C) begin
                casex(Rs1ForwardSrc_C)
                    HighLevelControl::Rs1_NO_FORWARD:       AluHazzardSafeOperandA_C = AluOperandA_C;
                    HighLevelControl::Rs1_ComputeResult:    AluHazzardSafeOperandA_C = ComputeResult_M;
                    HighLevelControl::Rs1_Rd1W:             AluHazzardSafeOperandA_C = Rd1_W;
                    HighLevelControl::Rs1_Rd1PostW:         AluHazzardSafeOperandA_C = Rd1_PostW;

                    default:                                AluHazzardSafeOperandA_C = 'x;
                endcase
            end
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

    ////                        **** ZICSR Modules ****                       ////
    `ifdef ZICSR

    assign CSRAdr_C = AluHazzardSafeOperandB_C[11:0];

    csrReadFile CSRReadFile(.clk, .reset,
                            .CSREn(CSREn_C), .CSROp(CSROp_C), .CSRReadEn(RegWrite_C),
                            .CSRAdr(CSRAdr_C), .WriteData(AluHazzardSafeOperandA_C),
                            .csr_control, .ReadData(CSRReadValue_C), .csr_values);

    ZICSR_CSRs Zicsr_CSRs (.clk, .reset,
                            .ustatus_ctrl(csr_control[ZICSRType::ustatus]),
                            .mstatus_ctrl(csr_control[ZICSRType::mstatus]),
                            .mtvec_ctrl  (csr_control[ZICSRType::mtvec  ]),
                            .mhartid_ctrl(csr_control[ZICSRType::mhartid])
    );
    `endif

    `ifdef ZICNTR
    ZICNTR_CSRs Zicntr_CSRs (.clk, .reset, .InstructionRetired(ValidInstruction_W),
                            // Assign to CSR signals
                        `ifdef XLEN_64
                            .CycleCSRValue (csr_values[ZICSRType::rdcycle ]),
                            .InsretCSRValue(csr_values[ZICSRType::rdinsret]),
                        `elsif XLEN_32
                            .CycleCSRValue ({csr_values[ZICSRType::rdcycleh ], csr_values[ZICSRType::rdcycle ]}),
                            .InsretCSRValue({csr_values[ZICSRType::rdinsreth], csr_values[ZICSRType::rdinsret]}),
                        `endif
                            .rdcycle_ctrl (csr_control[ZICSRType::rdcycle ]),
                            .rdtime_ctrl  (csr_control[ZICSRType::rdtime  ]),
                            .rdinsret_ctrl(csr_control[ZICSRType::rdinsret]),
                            .minsret_ctrl (csr_control[ZICSRType::minsret ])
                        `ifdef XLEN_32
                            , .rdcycleh_ctrl (csr_control[ZICSRType::rdcycleh ])
                            , .rdtimeh_ctrl  (csr_control[ZICSRType::rdtimeh  ])
                            , .rdinsreth_ctrl(csr_control[ZICSRType::rdinsreth])
                        `endif
    );
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
            `ifdef ZICSR
            HighLevelControl::CSRRead:      ComputeResult_C = CSRReadValue_C;
            `endif

            default:                        ComputeResult_C = 'x;

        endcase
    end

    assign DataMemAdrByteOffset_C = AluHazzardSafeOperandA_C[$clog2(`XLEN/8)-1:0] + AluHazzardSafeOperandB_C[$clog2(`XLEN/8)-1:0];

    // Determine Mem byte en bits

    always_comb begin
        localparam int BYTE_OFFSET_BITS = $clog2(`XLEN/8);
        logic[BYTE_OFFSET_BITS-1:0]    ByteOffset;
        logic misaligned;

        ByteOffset              = DataMemAdrByteOffset_C;
        MemWriteByteEn_C        = '0;

        case (StoreType_C)
            HighLevelControl::Store_Half_Word:    misaligned  = DataMemAdrByteOffset_C[0];      // halfword: bit0 must be 0
            HighLevelControl::Store_Word:         misaligned  = |DataMemAdrByteOffset_C[1:0];   // word: low 2 bits must be 0 (for 32-bit word)
            `ifdef XLEN_64
            HighLevelControl::Store_Double_Word:  misaligned  = |DataMemAdrByteOffset_C[2:0];   // dword: low 3 bits must be 0
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
                HighLevelControl::Rs2_NO_FORWARD:       MemWriteDataPreShift_C = Passthrough_C;
                HighLevelControl::Rs2_ComputeResult:    MemWriteDataPreShift_C = ComputeResult_M;
                HighLevelControl::Rs2_Rd1W:             MemWriteDataPreShift_C = Rd1_W;
                HighLevelControl::Rs2_Rd1PostW:         MemWriteDataPreShift_C = Rd1_PostW;

                default:                                MemWriteDataPreShift_C = 'x;
            endcase

        end

    `else

        assign MemWriteDataPreShift_C = Passthrough_C;

    `endif

    assign MemWriteData_C = MemWriteDataPreShift_C << (`XLENlg2'(DataMemAdrByteOffset_C)<<3);

endmodule
