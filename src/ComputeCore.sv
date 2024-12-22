//James Kaden Cassidy jkc.cassidy@gmail.com 12/19/2024

`define WORD_SIZE 32

module computeCore #(
    BIT_COUNT = 32
) (
    input logic clk,
    input logic reset,

    //To handle memory / chache externally
    output logic[BIT_COUNT-1 : 0] PC,       //Instruction Cache

    output logic MemEn,
    output logic MemWrite,                          //Command Memory to write
    output logic[(WORD_SIZE/8)-1:0] ByteEn,         //Bytes to be writen
    output logic[BIT_COUNT-1 : 0] MemAdr,           //Memory Adress
    output logic[WORD_SIZE-1 : 0] MemWriteData,      //Memory to be saved

    input logic[WORD_SIZE-1 : 0] Instr,
    input logic[WORD_SIZE-1 : 0] MemReadData,
);
    import HighLevelControl::*;

    logic RegWrite;

    logic[$clog2(BIT_COUNT) - 1 : 0] rs1Adr, rs2Adr, rd1Adr;

    logic[BIT_COUNT-1 : 0] PCNext, PCInc4, OldPC, Rd1, Rs1, Rs2, Imm, ALUOpA, ALUOpB, ALUResult, Result;

    //Bus assignments
    assign rs1Adr = Instr[19:15];
    assign rs2Adr = Instr[24:20];
    assign rd1Adr = Instr[11:7];

    //Conditional Signals to BIT_COUNT
    generate
        if (BIT_COUNT == 32) begin
            
        end else if (BIT_COUNT = 64) begin

        end else begin
            //initial begin
                $error("Unsupported BIT_COUNT: %0d", BIT_COUNT);
            //end
        end
    endgenerate

    //PC Source Select
    localparam PCMuxSrcSignalCount = 2;
    logic[BIT_COUNT-1 : 0] PCSrcSignals[PCMuxSrcSignalCount] = '{
        PCInc4, Result
    };
    mux #(WIDTH = BIT_COUNT, INPUT_BUS_COUNT = 2) PCSourceMux(PCSrc, PCSrcSignals, PCNext);

    //To involve further logic when implemented with branch prediction
    assign PCSrc = PCUpdate;

    //Program Counter
    flopR #(WIDTH = BIT_COUNT) ProgramCounter(.clk, .reset, .D(PCNext), .Q(PC));

    assign PCInc4 = PC + 4;

    //Instuction handline controlled externally

    //Controller Signals
    logic PCSrc, ResultSrc, PCUpdate, RegWrite;
    
    //Passed in signals : MemEn, ByteEn, MemWrite

    HighLevelControl::aluSrcA AluSrcA;
    HighLevelControl::aluSrcB AluSrcB;
    HighLevelControl::aluOperation ALUOp;

    HighLevelControl::immSrc ImmSrc;
    HighLevelControl::resultSrc ResultSrc;
    HighLevelControl::truncSrc TruncSrc;

    //Controller
    controller #(BIT_COUNT = BIT_COUNT) Controller(.Instr,
        .PCUpdate, .RegWrite, .ImmSrc, .ALUSrcA, .ALUSrcB, .ALUOp, .MemEn, 
        .MemWrite, .ByteEn, .ResultSrc, .TruncSrc);

    //Register File
    registerFile #(BIT_COUNT = BIT_COUNT, REGISTER_COUNT = BIT_COUNT) RegisterFile(
        .clk, .reset, .WriteEnable(RegWrite), .rs1Adr, .rs2Adr, .rd1Adr, .Rd1, .Rs1, .Rs2
    )

    immediateExtender #(BIT_COUNT = BIT_COUNT) ImmediateExtender(.ImmSrc,
            .Instr, .Imm);

    ////ALU Source Selection Muxes////
    
    //ALU Src A Mux
    always_comb begin
        casex(AluSrcA)
            aluSrcA::Rs1:   ALUOpA = Rs1;
            aluSrcA::OldPC: ALUOpA = OldPC;
            default:        ALUOpA = 'x;
        endcase
    end

    //ALU Src B Mux
    always_comb begin
        casex(AluSrcB)
            aluSrcB::Rs2: ALUOpB = Rs2;
            aluSrcB::Imm: ALUOpB = Imm;
            default:      ALUOpB = 'x;
        endcase
    end

    //ALU
    alu #(WIDTH = BIT_COUNT) ALU(.ALUOp, .ALUOpA, .ALUOpB, .ALUResult);

    ////Memory Cache handled externally////

    //**** ONLY WORKS FOR 32 BIT MEMORY****//
    assign MemWriteData = Rs2[31:0];

    //Result Select Mux

    always_comb begin
        casex(ResultSrc)
            //**** ONLY WORKS FOR 32 BIT MEMORY****//
            resultSrc::MemData: Result = {(BIT_COUNT-32) * MemReadData[31], MemReadData}; 
            resultSrc::ALU: Result = ALUResult;

            default:      Result = 'x;
        endcase
    end

    //Write Result to Register
    truncator(#BIT_COUNT = BIT_COUNT) Truncator(.TruncSrc, .Input(Result), .TruncResult(Rd1));
    
endmodule