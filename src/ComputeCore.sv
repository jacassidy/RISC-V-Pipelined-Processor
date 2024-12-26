//James Kaden Cassidy jkc.cassidy@gmail.com 12/19/2024

`define WORD_SIZE 32

module computeCore #(
    BIT_COUNT = 32
) (
    input   logic                       clk,
    input   logic                       reset,

    //To handle memory / chache externally
    output  logic[BIT_COUNT-1:0]        PC,       //Instruction Cache

    output  logic                       MemEn,
    output  logic                       MemWrite,       //Command Memory to write
    output  logic[(`WORD_SIZE/8)-1:0]   ByteEn,         //Bytes to be writen
    output  logic[BIT_COUNT-1:0]        MemAdr,         //Memory Adress
    output  logic[`WORD_SIZE-1:0]       MemWriteData,   //Memory to be saved

    input   logic[`WORD_SIZE-1:0]       Instr,
    input   logic[`WORD_SIZE-1:0]       MemReadData
);

    logic[$clog2(BIT_COUNT)-1:0] rs1Adr, rs2Adr, rd1Adr;

    logic[BIT_COUNT-1:0] PCNext, PCp4, OldPC, Rd1, Rs1, Rs2, 
            Imm, PCpImm, UpdatedPC, ALUOpA, ALUOpB, ALUResult, ComputeResult, Result;

    //Controller Signals
    logic RegWrite, Zero, oVerflow, Carry, Negative;
    //Passed in signals : MemEn, ByteEn, MemWrite

    HighLevelControl::pcSrc             PCSrc;
    HighLevelControl::pcSrc             PCSrcPostConditional;
    HighLevelControl::conditionalPCSrc  ConditionalPCSrc;

    HighLevelControl::immSrc            ImmSrc;
    HighLevelControl::updatedPCSrc      UpdatedPCSrc;

    // HighLevelControl::aluSrcA           AluSrcA;
    HighLevelControl::aluSrcB           ALUSrcB;
    HighLevelControl::aluOperation      ALUOp;

    HighLevelControl::computeSrc        ComputeSrc;
    HighLevelControl::resultSrc         ResultSrc;
    HighLevelControl::truncSrc          TruncSrc;

    //Bus assignments
    assign rs1Adr = Instr[19:15];
    assign rs2Adr = Instr[24:20];
    assign rd1Adr = Instr[11:7];

    //Conditional Signals to BIT_COUNT
    generate
        if (BIT_COUNT == 32) begin
            
        end else if (BIT_COUNT == 64) begin

        end else begin
            //initial begin
                $error("Unsupported BIT_COUNT: %0d", BIT_COUNT);
            //end
        end
    endgenerate

    ////                        **** I STAGE ****                       ////

    //PC Source Select Mux implemented with branch prediction
    pcUpdateHandler #(.BIT_COUNT(BIT_COUNT)) PCUpdateHandler(.PCSrc_R(PCSrc), 
            .PCSrcPostConditional_C(PCSrcPostConditional), .Predict(1'b0), .Prediction({BIT_COUNT * 1'b0}),
            .PredictionCorrect_C(1'b0), .PCp4, .AluAdd_C(ALUResult), .PCpImm_R(PCpImm), 
            .UpdatedPC_C(UpdatedPC), .PCNext);

    //Program Counter
    flopR #(.WIDTH(BIT_COUNT)) ProgramCounter(.clk, .reset, .D(PCNext), .Q(PC));

    assign PCp4 = PC + 4;

    //****Instuction handline controlled externally****//

    //While not pipelined
    assign OldPC = PC;

    ////                        **** R STAGE ****                       ////
    //Controller
    controller #(.BIT_COUNT(BIT_COUNT)) Controller(.Instr,
        .PCSrc, .ConditionalPCSrc, .RegWrite, .ImmSrc, .UpdatedPCSrc, .ALUSrcB, 
        .ALUOp, .ComputeSrc, .MemEn, .MemWrite, .ByteEn, .ResultSrc, .TruncSrc);

    //Register File
    registerFile #(.BIT_COUNT(BIT_COUNT), .REGISTER_COUNT(BIT_COUNT)) RegisterFile(
        .clk, .reset, .WriteEnable(RegWrite), .rs1Adr, .rs2Adr, .rd1Adr, .Rd1, .Rs1, .Rs2
    );

    //Immediate Extender
    immediateExtender #(.BIT_COUNT(BIT_COUNT)) ImmediateExtender(.ImmSrc, .Instr, .Imm(Imm));

    //Jump / Branch Adder
    assign PCpImm = Imm + OldPC;

    //Updated PC Mux
    always_comb begin
        casex(UpdatedPCSrc)
            HighLevelControl::PCpImm:   UpdatedPC = PCpImm;
            HighLevelControl::PCp4:     UpdatedPC = PCp4;

            default:  UpdatedPC = 'x;
        endcase
    end

    ////ALU Source Selection Muxes////
    
    //ALU Src A Mux
    assign ALUOpA = Rs1;

    //ALU Src B Mux
    always_comb begin
        casex(ALUSrcB)
            HighLevelControl::Rs2: ALUOpB = Rs2;
            HighLevelControl::Imm: ALUOpB = Imm;
            default:      ALUOpB = 'x;
        endcase
    end

    ////                        **** C STAGE ****                       ////

    //ALU
    behavioralAlu #(.BIT_COUNT(BIT_COUNT)) ALU(.ALUOp, .ALUOpA, .ALUOpB, .Zero,
                .oVerflow, .Negative, .Carry, .ALUResult);

    branchHandler BranchHandler(.PCSrc_C(PCSrc), .ConditionalPCSrc_C(ConditionalPCSrc), 
            .Zero, .Carry, .Negative, .oVerflow, 
            .PCSrcPostConditional_C(PCSrcPostConditional));

    //Compute Result Select Mux
    always_comb begin
        casex(ComputeSrc)
            HighLevelControl::ALU:        ComputeResult = ALUResult;
            HighLevelControl::ALUOpB:     ComputeResult = ALUOpB;
            HighLevelControl::UpdatedPC:  ComputeResult = UpdatedPC;

            default: ComputeResult = 'x;

        endcase
    end

    ////                        **** M STAGE ****                       ////

    ////Memory Cache handled externally////

    //**** ONLY WORKS FOR 32 BIT MEMORY****//
    assign MemWriteData = ALUOpB[31:0];

    //Result Select Mux

    always_comb begin
        casex(ResultSrc)
            //**** ONLY WORKS FOR 32 BIT MEMORY****//
            HighLevelControl::Memory:     Result = {(BIT_COUNT-32) * MemReadData[31], MemReadData}; 
            HighLevelControl::Compute:    Result = ComputeResult;

            default:    Result = 'x;
        endcase
    end

    ////                        **** W STAGE ****                       ////

    //Write Result to Register
    truncator #(.BIT_COUNT(BIT_COUNT)) Truncator(.TruncSrc, .Input(Result), .TruncResult(Rd1));
    
endmodule