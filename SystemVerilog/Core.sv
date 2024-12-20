module core #(
    WORD_SIZE = 32
) (
    input logic clk,
    input logic reset,

    //To handle memory / chache externally
    output logic[WORD_SIZE-1 : 0] PC,       //Instruction Cache

    output logic MemWrite,                   //Command Memory to write
    output logic[WORD_SIZE-1 : 0] ALUResult, //Memory Cache
    output logic[WORD_SIZE-1 : 0] ____,      //Memory to be saved

    input logic[WORD_SIZE-1 : 0] Instr,
    input logic[WORD_SIZE-1 : 0] MemData,
);
    logic RegWrite;

    logic[$clog2(WORD_SIZE) - 1 : 0] rs1Adr, rs2Adr, rd1Adr;

    logic[2:0] funct3;
    logic[6:0] opcode, funct7;

    logic[WORD_SIZE-1 : 0] PCNext, PCInc4, OldPC, Rd1, Rs1, Rs2, Imm, ALUOpA, ALUOpB, ALUResult, Result;

    //Bus assignments
    assign opcode = Instr[6:0];
    assign funct3 = Instr[14:12];
    assign funct7 = Instr[31:25];

    assign rs1Adr = Instr[19:15];
    assign rs2Adr = Instr[24:20];
    assign rd1Adr = Instr[11:7];

    //Conditional Signals to WORD_SIZE
    generate
        if (WORD_SIZE == 32) begin
            
        end else if (WORD_SIZE = 64) begin

        end else begin
            //initial begin
                $error("Unsupported WORD_SIZE: %0d", WORD_SIZE);
            //end
        end
    endgenerate

    //PC Source Select
    localparam PCMuxSrcSignalCount = 2;
    logic[WORD_SIZE-1 : 0] PCSrcSignals[PCMuxSrcSignalCount] = '{
        PCInc4, Result
    };
    mux #(WIDTH = WORD_SIZE, INPUT_BUS_COUNT = 2) PCSourceMux(PCSrc, PCSrcSignals, PCNext);

    //To involve further logic when implemented with branch prediction
    assign PCSrc = PCUpdate;

    //Program Counter
    flopR #(WIDTH = WORD_SIZE) ProgramCounter(.clk, .reset, .D(PCNext), .Q(PC));

    assign PCInc4 = PC + 4;

    //Instuction handline controlled externally

    //Controller Signals
    logic AluSrcA, AluSrcB, PCSrc, ResultSrc, PCUpdate, RegWrite;

    ALUControl::operation ALUCtrl;
    HighLevelControl::immExtender ImmSrc;

    //Controller
    controller #(WORD_SIZE = WORD_SIZE) Controller(.opcode, .funct3, .funct7,
        .PCUpdate, .RegWrite, .ImmSrc, .ALUSrcA, .ALUSrcB, .ALUCtrl, .MemWrite);

    //Register File
    registerFile #(WORD_SIZE = WORD_SIZE, REGISTER_COUNT = WORD_SIZE) RegisterFile(
        .clk, .reset, .WriteEnable(RegWrite), .rs1Adr, .rs2Adr, .rd1Adr, .Rd1, .Rs1, .Rs2
    )

    //ALU Source Selection Muxes
    localparam ALUSrcAMuxInputCount = 2;
    logic[WORD_SIZE-1 : 0] AluMuxASrcSignals[ALUSrcAMuxInputCount] = '{
        Rs1, OldPC
    };
    mux #(WIDTH = WORD_SIZE, INPUT_BUS_COUNT = ALUSrcAMuxInputCount) ALUSrcAMux(
        AluSrcA, AluMuxASrcSignals, ALUOpA
    );

    localparam ALUSrcBMuxInputCount = 2;
    logic[WORD_SIZE-1 : 0] AluMuxBSrcSignals[ALUSrcBMuxInputCount] = '{
        Rs2, Imm
    };
    mux #(WIDTH = WORD_SIZE, INPUT_BUS_COUNT = ALUSrcBMuxInputCount) ALUSrcBMux(
        AluSrcB, AluMuxBSrcSignals, ALUOpB
    );

    //ALU
    alu #(WIDTH = WORD_SIZE) ALU(.ALUCtrl, .ALUOpA, .ALUOpB, .ALUResult);

    //Memory Cache handled externally

    //Result Select
    localparam ResultSrcMuxInputCount = 2
    logic[WORD_SIZE - 1 : 0] ResultMuxSrcSignals[ResultSrcMuxInputCount] = '{
        MemData, ALUResult
    };
    mux #(WIDTH = WORD_SIZE, INPUT_BUS_COUNT = ResultSrcMuxInputCount ) ResultSelectMux(
        ResultSrc, ResultMuxSrcSignals, Result
    );

    //Write Result to Register
    assign Rd1 = Result;

    
endmodule