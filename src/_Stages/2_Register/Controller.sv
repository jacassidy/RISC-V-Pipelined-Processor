//James Kaden Cassidy jkc.cassidy@gmail.com 12/20/2024

`define WORD_SIZE 32

//               (1       +1      +1        +(`WORD_SIZE/8))
//                {RegWrite, MemEn, MemWrite,      ByteEn}
`define SIGNAL_SIZE 7

typedef struct packed {
    
    logic[`SIGNAL_SIZE-1:0]  signals;

    HighLevelControl::pcSrc                   PCSrc;
    HighLevelControl::conditionalPCSrc        ConditionalPCSrc;

    HighLevelControl::immSrc                  ImmSrc;
    HighLevelControl::updatedPCSrc            UpdatedPCSrc;

    HighLevelControl::aluSrcB                 ALUSrcB;
    HighLevelControl::aluOperation            ALUOp;

    HighLevelControl::computeSrc              ComputeSrc;
    HighLevelControl::resultSrc               ResultSrc;
    HighLevelControl::truncSrc                TruncSrc;

} controlSignals;

function automatic void setControllerX(ref controlSignals ctrl);
    ctrl.signals          = 'x;

    ctrl.PCSrc            = HighLevelControl::pcSrc'('x);
    ctrl.ConditionalPCSrc = HighLevelControl::conditionalPCSrc'('x);

    ctrl.ImmSrc           = HighLevelControl::immSrc'('x);
    ctrl.UpdatedPCSrc     = HighLevelControl::updatedPCSrc'('x);

    ctrl.ALUSrcB          = HighLevelControl::aluSrcB'('x);
    ctrl.ALUOp            = HighLevelControl::aluOperation'('x);

    ctrl.ComputeSrc       = HighLevelControl::computeSrc'('x);
    ctrl.ResultSrc        = HighLevelControl::resultSrc'('x);
    ctrl.TruncSrc         = HighLevelControl::truncSrc'('x);
endfunction

module controller #(
    BIT_COUNT
) (
    input   logic[`WORD_SIZE-1:0]       Instr,

    output HighLevelControl::pcSrc                        PCSrc,
    output HighLevelControl::conditionalPCSrc             ConditionalPCSrc,
    output logic                        RegWrite,

    output HighLevelControl::immSrc                       ImmSrc,
    output HighLevelControl::updatedPCSrc                 UpdatedPCSrc,

    output HighLevelControl::aluSrcB                      ALUSrcB,
    output HighLevelControl::aluOperation                 ALUOp,

    output HighLevelControl::computeSrc                   ComputeSrc,

    output logic                        MemEn,
    output logic                        MemWrite,
    output logic[(`WORD_SIZE/8)-1:0]    ByteEn,

    output HighLevelControl::resultSrc                    ResultSrc,
    output HighLevelControl::truncSrc                     TruncSrc
);
    logic[2:0] funct3;
    logic[6:0] opcode, funct7;

    //Bus Assignments
    assign opcode = Instr[6:0];
    assign funct3 = Instr[14:12];
    assign funct7 = Instr[31:25];

    controlSignals Controller, RType, IType, ISType, LType, SType, UType, JType, BType;

    //Transition to enum to simplify
    assign {RegWrite, MemEn, MemWrite, ByteEn} = Controller.signals;

    assign PCSrc            = Controller.PCSrc;
    assign ConditionalPCSrc = Controller.ConditionalPCSrc;

    assign ImmSrc           = Controller.ImmSrc;
    assign UpdatedPCSrc     = Controller.UpdatedPCSrc;

    assign ALUSrcB          = Controller.ALUSrcB;
    assign ALUOp            = Controller.ALUOp;

    assign ComputeSrc       = Controller.ComputeSrc;
    assign ResultSrc        = Controller.ResultSrc;
    assign TruncSrc         = Controller.TruncSrc;

    //R-Type Controller
    rTypeController     RTypeController (.funct7,   .funct3,            .Controller(RType)  );
    iTypeController     ITypeController (.funct3,                       .Controller(IType)  );
    isTypeController    ISTypeController(.funct7,   .funct3,            .Controller(ISType) );
    lTypeController     LTypeController (.funct3,                       .Controller(LType)  );
    sTypeController     STypeController (.funct3,                       .Controller(SType)  );
    uTypeController     UTypeController (.opcode,                       .Controller(UType)  );
    jTypeController     JTypeController (.opcode,                       .Controller(JType)  );
    bTypeController     BTypeController (.funct3,                       .Controller(BType)  );

    always_comb begin
        casex(opcode)
            7'b0110011: Controller = RType;
            7'b0010011: Controller = IType;
            7'b0010011: Controller = ISType;
            7'b0000011: Controller = LType; 
            7'b0100011: Controller = SType; 
            7'b0x10111: Controller = UType; 
            7'b110x111: Controller = JType;

            default: begin
                setControllerX(Controller);
                //{RegWrite, MemEn, MemWrite,      ByteEn}
                Controller.signals = `SIGNAL_SIZE'b0_0_0_000;
            end
        endcase
    end
    
endmodule

//Operation between Rs1 Rs2 and put in Rd1
module rTypeController(
    input logic[6:0] funct7,
    input logic[2:0] funct3,

    output controlSignals Controller
);

    //{RegWrite, MemEn, MemWrite, ByteEn}
    assign Controller.signals           = `SIGNAL_SIZE'b1_0_0_0000;

    assign Controller.PCSrc             = HighLevelControl::PCp4_I;
    assign Controller.ConditionalPCSrc  = HighLevelControl::NO_BRANCH;

    assign Controller.ImmSrc            = HighLevelControl::immSrc'('x);
    assign Controller.UpdatedPCSrc      = HighLevelControl::updatedPCSrc'('x);

    assign Controller.ALUSrcB           = HighLevelControl::Rs2;

    assign Controller.ComputeSrc        = HighLevelControl::ALU;
    assign Controller.ResultSrc         = HighLevelControl::Compute;
    assign Controller.TruncSrc          = HighLevelControl::NO_TRUNC;
    
    always_comb begin
        casex({funct7, funct3})
            10'b0000000_000: Controller.ALUOp = HighLevelControl::ADD;
            10'b0100000_000: Controller.ALUOp = HighLevelControl::SUB;
            10'b0000000_110: Controller.ALUOp = HighLevelControl::OR;
            10'b0000000_111: Controller.ALUOp = HighLevelControl::AND;
            10'b0000000_100: Controller.ALUOp = HighLevelControl::XOR;
            10'b0000000_001: Controller.ALUOp = HighLevelControl::SLL;
            10'b0000000_010: Controller.ALUOp = HighLevelControl::SLT;
            10'b0000000_011: Controller.ALUOp = HighLevelControl::SLTU;
            10'b0000000_101: Controller.ALUOp = HighLevelControl::SRL;
            10'b0100000_101: Controller.ALUOp = HighLevelControl::SRA;
            
            default: Controller.ALUOp = HighLevelControl::aluOperation'('x);
            
        endcase
    end

endmodule

//Operation between Rs1 and Imm put in Rd1
module iTypeController(
    input logic[2:0] funct3,

    output controlSignals Controller
);

    //{RegWrite, MemEn, MemWrite, ByteEn}
    assign Controller.signals           = `SIGNAL_SIZE'b1_0_0_0000;

    assign Controller.PCSrc             = HighLevelControl::PCp4_I;
    assign Controller.ConditionalPCSrc  = HighLevelControl::NO_BRANCH;

    assign Controller.ImmSrc            = HighLevelControl::Imm11t0;
    assign Controller.UpdatedPCSrc      = HighLevelControl::updatedPCSrc'('x);

    assign Controller.ALUSrcB           = HighLevelControl::Imm;

    assign Controller.ComputeSrc        = HighLevelControl::ALU;
    assign Controller.ResultSrc         = HighLevelControl::Compute;
    assign Controller.TruncSrc          = HighLevelControl::NO_TRUNC;
    
    always_comb begin
        casex(funct3)
            3'b000: Controller.ALUOp = HighLevelControl::ADD;

            3'b110: Controller.ALUOp = HighLevelControl::OR;
            3'b111: Controller.ALUOp = HighLevelControl::AND; 
            3'b100: Controller.ALUOp = HighLevelControl::XOR;

            3'b010: Controller.ALUOp = HighLevelControl::SLT;
            3'b011: Controller.ALUOp = HighLevelControl::SLTU;
            
            default: Controller.ALUOp = HighLevelControl::aluOperation'('x);
            
        endcase
    end

endmodule

//Shift operation between Rs1 and Imm put in Rd1
module isTypeController(
    input logic[6:0] funct7,
    input logic[2:0] funct3,

    output controlSignals Controller
);

    //{RegWrite, MemEn, MemWrite, ByteEn}
    assign Controller.signals           = `SIGNAL_SIZE'b1_0_0_0000;

    assign Controller.PCSrc             = HighLevelControl::PCp4_I;
    assign Controller.ConditionalPCSrc  = HighLevelControl::NO_BRANCH;

    assign Controller.ImmSrc            = HighLevelControl::Imm4t0;
    assign Controller.UpdatedPCSrc      = HighLevelControl::updatedPCSrc'('x);

    assign Controller.ALUSrcB           = HighLevelControl::Imm;

    assign Controller.ComputeSrc        = HighLevelControl::ALU;
    assign Controller.ResultSrc         = HighLevelControl::Compute;
    assign Controller.TruncSrc          = HighLevelControl::NO_TRUNC;
    
    always_comb begin
        casex({funct7, funct3})
            10'b0000000_001: Controller.ALUOp = HighLevelControl::SLL;
            10'b0000000_101: Controller.ALUOp = HighLevelControl::SRL;
            10'b0100000_101: Controller.ALUOp = HighLevelControl::SRA;
            
            default:         Controller.ALUOp = HighLevelControl::aluOperation'('x);
            
        endcase
    end

endmodule

//Operation between Rs1 and Imm to load a value to Rd1
module lTypeController(
    input logic[2:0] funct3,

    output controlSignals Controller
);

    //{RegWrite, MemEn, MemWrite, ByteEn}
    assign Controller.signals           = `SIGNAL_SIZE'b1_1_0_0000;

    assign Controller.PCSrc             = HighLevelControl::PCp4_I;
    assign Controller.ConditionalPCSrc  = HighLevelControl::NO_BRANCH;

    assign Controller.ImmSrc            = HighLevelControl::Imm11t0;
    assign Controller.UpdatedPCSrc      = HighLevelControl::updatedPCSrc'('x);

    assign Controller.ALUSrcB           = HighLevelControl::Imm;
    assign Controller.ALUOp             = HighLevelControl::ADD;

    assign Controller.ComputeSrc        = HighLevelControl::ALU;
    assign Controller.ResultSrc         = HighLevelControl::Memory;
    
    always_comb begin
        casex(funct3)
            3'b000: Controller.TruncSrc = HighLevelControl::BYTE;
            3'b001: Controller.TruncSrc = HighLevelControl::HALF_WORD;
            3'b010: Controller.TruncSrc = HighLevelControl::WORD;
            3'b100: Controller.TruncSrc = HighLevelControl::BYTE_UNSIGNED;
            3'b101: Controller.TruncSrc = HighLevelControl::HALF_WORD_UNSIGNED;
            
            default: Controller.TruncSrc = HighLevelControl::truncSrc'('x);
            
        endcase
    end

endmodule

//**** ONLY WORKS FOR 32 BIT MEMORY****// (ByteEn is 4 bits)
//Operation between Rs1 and Imm to save Rs2 to memory
module sTypeController(
    input logic[2:0] funct3,
    
    output controlSignals Controller
);

    assign Controller.PCSrc             = HighLevelControl::PCp4_I;
    assign Controller.ConditionalPCSrc  = HighLevelControl::NO_BRANCH;

    assign Controller.ImmSrc            = HighLevelControl::SType;
    assign Controller.UpdatedPCSrc      = HighLevelControl::updatedPCSrc'('x);

    assign Controller.ALUSrcB           = HighLevelControl::Imm;
    assign Controller.ALUOp             = HighLevelControl::ADD;

    assign Controller.ComputeSrc        = HighLevelControl::ALU;
    assign Controller.ResultSrc         = HighLevelControl::resultSrc'('x);
    assign Controller.TruncSrc          = HighLevelControl::truncSrc'('x);
    
    always_comb begin
        casex(funct3)
            //{RegWrite, MemEn, MemWrite, ByteEn}
            3'b000:  Controller.signals = `SIGNAL_SIZE'b0_1_1_0001; //SB
            3'b001:  Controller.signals = `SIGNAL_SIZE'b0_1_1_0011; //SH
            3'b010:  Controller.signals = `SIGNAL_SIZE'b0_1_1_1111; //SW
            
            default: Controller.signals = 'x;
            
        endcase
    end
endmodule

//Operation with upper immediate put into Rd1
module uTypeController(
    input logic[6:0] opcode,
    
    output controlSignals Controller
);

    //{RegWrite, MemEn, MemWrite, ByteEn}
    assign Controller.signals           = `SIGNAL_SIZE'b1_0_0_0000; 

    assign Controller.PCSrc             = HighLevelControl::PCp4_I;
    assign Controller.ConditionalPCSrc  = HighLevelControl::NO_BRANCH;

    assign Controller.ALUOp             = HighLevelControl::aluOperation'('x);

    assign Controller.ImmSrc            = HighLevelControl::UType;
    assign Controller.UpdatedPCSrc      = HighLevelControl::PCpImm;

    assign Controller.ResultSrc         = HighLevelControl::Compute;
    assign Controller.TruncSrc          = HighLevelControl::NO_TRUNC;

    always_comb begin
        casex(opcode)
            7'b0110111: begin
                Controller.ALUSrcB      = HighLevelControl::Imm;
                Controller.ComputeSrc   = HighLevelControl::ALUOpB; //LUI
            end
            7'b0010111: begin
                Controller.ALUSrcB      = HighLevelControl::aluSrcB'('x);
                Controller.ComputeSrc   = HighLevelControl::UpdatedPC; //AUIPC
            end
            
            default:    begin
                Controller.ALUSrcB      = HighLevelControl::aluSrcB'('x);
                Controller.ComputeSrc   = HighLevelControl::computeSrc'('x); 
            end
            
        endcase
    end

endmodule

//Operation PC+4 goes into Rd1 and AluOpB + PC goes into PC
module jTypeController(
    input logic[6:0] opcode,

    output controlSignals Controller
);

    //{RegWrite, MemEn, MemWrite, ByteEn}
    assign Controller.signals           = `SIGNAL_SIZE'b1_0_0_0000; 

    assign Controller.ConditionalPCSrc  = HighLevelControl::NO_BRANCH;
    
    assign Controller.UpdatedPCSrc      = HighLevelControl::PCp4;

    assign Controller.ALUOp             = HighLevelControl::aluOperation'('x);

    assign Controller.ComputeSrc        = HighLevelControl::UpdatedPC;
    assign Controller.ResultSrc         = HighLevelControl::Compute;
    assign Controller.TruncSrc          = HighLevelControl::NO_TRUNC;

    always_comb begin
        casex(opcode)
            7'b1101111: begin //JAL
                Controller.PCSrc            = HighLevelControl::Jump_R;
    
                Controller.ImmSrc           = HighLevelControl::JType;

                Controller.ALUSrcB          = HighLevelControl::aluSrcB'('x);
            end 

            7'b1100111: begin //JALR
                Controller.PCSrc            = HighLevelControl::Jump_C;

                Controller.ImmSrc           = HighLevelControl::Imm11t0;

                Controller.ALUSrcB          = HighLevelControl::Imm;
            end
            
            
            default: begin
                Controller.PCSrc            = HighLevelControl::pcSrc'('x);

                Controller.ImmSrc           = HighLevelControl::immSrc'('x);

                Controller.ALUSrcB          = HighLevelControl::aluSrcB'('x);
            end
            
        endcase
    end

endmodule

//Operation between Rs1 and Rs2 to determine if Imm + PC goes into PC
module bTypeController(
    input logic[2:0] funct3,

    output controlSignals Controller
);
    //{RegWrite, MemEn, MemWrite, ByteEn}
    assign Controller.signals           = `SIGNAL_SIZE'b0_0_0_0000;

    assign Controller.PCSrc             = HighLevelControl::Branch_C;

    assign Controller.ImmSrc            = HighLevelControl::BType;
    assign Controller.UpdatedPCSrc      = HighLevelControl::PCpImm;

    assign Controller.ALUSrcB           = HighLevelControl::Rs2;
    assign Controller.ALUOp             = HighLevelControl::SUB;

    assign Controller.ComputeSrc        = HighLevelControl::computeSrc'('x);
    assign Controller.ResultSrc         = HighLevelControl::resultSrc'('x);
    assign Controller.TruncSrc          = HighLevelControl::truncSrc'('x);
    
    always_comb begin
        casex(funct3)
            3'b000: Controller.ConditionalPCSrc  = HighLevelControl::BEQ_C;
            3'b001: Controller.ConditionalPCSrc  = HighLevelControl::BNE_C;
            3'b100: Controller.ConditionalPCSrc  = HighLevelControl::BLT_C;
            3'b101: Controller.ConditionalPCSrc  = HighLevelControl::BGE_C;
            3'b110: Controller.ConditionalPCSrc  = HighLevelControl::BLTU_C;
            3'b111: Controller.ConditionalPCSrc  = HighLevelControl::BGEU_C;
            
            default: Controller.ConditionalPCSrc = HighLevelControl::conditionalPCSrc'('x);
            
        endcase
    end

endmodule