//James Kaden Cassidy jkc.cassidy@gmail.com 12/20/2024

import HighLevelControl::*;

`define WORD_SIZE 32

//               (1       +1      +1        +(`WORD_SIZE/8))
//                {RegWrite, MemEn, MemWrite,      ByteEn}
`define SIGNAL_SIZE 7

typedef struct packed {
    
    logic[`SIGNAL_SIZE-1:0]  signals;

    pcSrc                   PCSrc;
    conditionalPCSrc        ConditionalPCSrc;

    immSrc                  ImmSrc;
    updatedPCSrc            UpdatedPCSrc;

    aluSrcB                 ALUSrcB;
    aluOperation            ALUOp;

    computeSrc              ComputeSrc;
    resultSrc               ResultSrc;
    truncSrc                TruncSrc;

} controlSignals;

function automatic void setControllerX(ref controlSignals ctrl);
    ctrl.signals          = 'x;

    ctrl.PCSrc            = pcSrc'('x);
    ctrl.ConditionalPCSrc = conditionalPCSrc'('x);

    ctrl.ImmSrc           = immSrc'('x);
    ctrl.UpdatedPCSrc     = updatedPCSrc'('x);

    ctrl.ALUSrcB          = aluSrcB'('x);
    ctrl.ALUOp            = aluOperation'('x);

    ctrl.ComputeSrc       = computeSrc'('x);
    ctrl.ResultSrc        = resultSrc'('x);
    ctrl.TruncSrc         = truncSrc'('x);
endfunction

module controller #(
    BIT_COUNT
) (
    input   logic[`WORD_SIZE-1:0]       Instr,

    output pcSrc                        PCSrc,
    output conditionalPCSrc             ConditionalPCSrc,
    output logic                        RegWrite,

    output immSrc                       ImmSrc,
    output updatedPCSrc                 UpdatedPCSrc,

    output aluSrcB                      ALUSrcB,
    output aluOperation                 ALUOp,

    output computeSrc                   ComputeSrc,

    output logic                        MemEn,
    output logic                        MemWrite,
    output logic[(`WORD_SIZE/8)-1:0]    ByteEn,

    output resultSrc                    ResultSrc,
    output truncSrc                     TruncSrc
);
    logic[2:0] funct3;
    logic[6:0] opcode, funct7;

    //Bus Assignments
    assign opcode = Instr[6:0];
    assign funct3 = Instr[14:12];
    assign funct7 = Instr[31:25];

    controlSignals Controller, RType, IType, ISType, LType, Stype, UType, JType, BType;

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

    assign Controller.PCSrc             = PCp4_I;
    assign Controller.ConditionalPCSrc  = NO_BRANCH;

    assign Controller.ImmSrc            = immSrc'('x);
    assign Controller.UpdatedPCSrc      = updatedPCSrc'('x);

    assign Controller.ALUSrcB           = Rs2;

    assign Controller.ComputeSrc        = ALU;
    assign Controller.ResultSrc         = Compute;
    assign Controller.TruncSrc          = NO_TRUNC;
    
    always_comb begin
        casex({funct7, funct3})
            10'b0000000_000: Controller.ALUOp = ADD;
            10'b0100000_000: Controller.ALUOp = SUB;
            10'b0000000_110: Controller.ALUOp = OR;
            10'b0000000_111: Controller.ALUOp = AND;
            10'b0000000_100: Controller.ALUOp = XOR;
            10'b0000000_001: Controller.ALUOp = SLL;
            10'b0000000_010: Controller.ALUOp = SLT;
            10'b0000000_011: Controller.ALUOp = SLTU;
            10'b0000000_101: Controller.ALUOp = SRL;
            10'b0100000_101: Controller.ALUOp = SRA;
            
            default: Controller.ALUOp = aluOperation'('x);
            
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

    assign Controller.PCSrc             = PCp4_I;
    assign Controller.ConditionalPCSrc  = NO_BRANCH;

    assign Controller.ImmSrc            = Imm11t0;
    assign Controller.UpdatedPCSrc      = updatedPCSrc'('x);

    assign Controller.ALUSrcB           = Imm;

    assign Controller.ComputeSrc        = ALU;
    assign Controller.ResultSrc         = Compute;
    assign Controller.TruncSrc          = NO_TRUNC;
    
    always_comb begin
        casex(funct3)
            3'b000: Controller.ALUOp = ADD;

            3'b110: Controller.ALUOp = OR;
            3'b111: Controller.ALUOp = AND; 
            3'b100: Controller.ALUOp = XOR;

            3'b010: Controller.ALUOp = SLT;
            3'b011: Controller.ALUOp = SLTU;
            
            default: Controller.ALUOp = aluOperation'('x);
            
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

    assign Controller.PCSrc             = PCp4_I;
    assign Controller.ConditionalPCSrc  = NO_BRANCH;

    assign Controller.ImmSrc            = Imm4t0;
    assign Controller.UpdatedPCSrc      = updatedPCSrc'('x);

    assign Controller.ALUSrcB           = Imm;

    assign Controller.ComputeSrc        = ALU;
    assign Controller.ResultSrc         = Compute;
    assign Controller.TruncSrc          = NO_TRUNC;
    
    always_comb begin
        casex({funct7, funct3})
            10'b0000000_001: Controller.ALUOp = SLL;
            10'b0000000_101: Controller.ALUOp = SRL;
            10'b0100000_101: Controller.ALUOp = SRA;
            
            default:         Controller.ALUOp = aluOperation'('x);
            
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

    assign Controller.PCSrc             = PCp4_I;
    assign Controller.ConditionalPCSrc  = NO_BRANCH;

    assign Controller.ImmSrc            = Imm11t0;
    assign Controller.UpdatedPCSrc      = updatedPCSrc'('x);

    assign Controller.ALUSrcB           = Imm;
    assign Controller.ALUOp             = ADD;

    assign Controller.ComputeSrc        = ALU;
    assign Controller.ResultSrc         = Memory;
    
    always_comb begin
        casex(funct3)
            3'b000: Controller.TruncSrc = BYTE;
            3'b001: Controller.TruncSrc = HALF_WORD;
            3'b010: Controller.TruncSrc = WORD;
            3'b100: Controller.TruncSrc = BYTE_UNSIGNED;
            3'b101: Controller.TruncSrc = HALF_WORD_UNSIGNED;
            
            default: Controller.TruncSrc = truncSrc'('x);
            
        endcase
    end

endmodule

//**** ONLY WORKS FOR 32 BIT MEMORY****// (ByteEn is 4 bits)
//Operation between Rs1 and Imm to save Rs2 to memory
module sTypeController(
    input logic[2:0] funct3,
    
    output controlSignals Controller
);

    assign Controller.PCSrc             = PCp4_I;
    assign Controller.ConditionalPCSrc  = NO_BRANCH;

    assign Controller.ImmSrc            = SType;
    assign Controller.UpdatedPCSrc      = updatedPCSrc'('x);

    assign Controller.ALUSrcB           = Imm;
    assign Controller.ALUOp             = ADD;

    assign Controller.ComputeSrc        = ALU;
    assign Controller.ResultSrc         = resultSrc'('x);
    assign Controller.TruncSrc          = truncSrc'('x);
    
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

    assign Controller.PCSrc             = PCp4_I;
    assign Controller.ConditionalPCSrc  = NO_BRANCH;

    assign Controller.ALUSrcB           = aluSrcB'('x);
    assign Controller.ALUOp             = aluOperation'('x);

    assign Controller.ImmSrc            = UType;
    assign Controller.UpdatedPCSrc      = PCpImm;

    assign Controller.ResultSrc         = Compute;
    assign Controller.TruncSrc          = NO_TRUNC;

    always_comb begin
        casex(opcode)
            7'b0110111: Controller.ComputeSrc    = ALUOpB; //LUI
            7'b0010111: Controller.ComputeSrc    = UpdatedPC; //AUIPC
            
            default:    Controller.ComputeSrc    = computeSrc'('x); 
            
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

    assign Controller.ConditionalPCSrc  = NO_BRANCH;
    
    assign Controller.UpdatedPCSrc      = PCp4;

    assign Controller.ALUOp             = aluOperation'('x);

    assign Controller.ComputeSrc        = UpdatedPC;
    assign Controller.ResultSrc         = Compute;
    assign Controller.TruncSrc          = NO_TRUNC;

    always_comb begin
        casex(opcode)
            7'b1101111: begin //JAL
                Controller.PCSrc            = Jump_R;
    
                Controller.ImmSrc           = JType;

                Controller.ALUSrcB          = aluSrcB'('x);
            end 

            7'b1100111: begin //JALR
                Controller.PCSrc            = Jump_C;

                Controller.ImmSrc           = Imm11t0;

                Controller.ALUSrcB          = Imm;
            end
            
            
            default: begin
                Controller.PCSrc            = pcSrc'('x);

                Controller.ImmSrc           = immSrc'('x);

                Controller.ALUSrcB          = aluSrcB'('x);
            end
            
        endcase
    end

endmodule

//Operation between Rs1 and Rs2 to determine if Imm + PC goes into PC
module bTypeController(
    input logic[2:0] funct3,

    output controlSignals Controller
);
    import HighLevelControl::*;
    //{RegWrite, MemEn, MemWrite, ByteEn}
    assign Controller.signals           = `SIGNAL_SIZE'b0_0_0_0000;

    assign Controller.PCSrc             = Branch_C;

    assign Controller.ImmSrc            = BType;
    assign Controller.UpdatedPCSrc      = PCpImm;

    assign Controller.ALUSrcB           = Rs2;
    assign Controller.ALUOp             = SUB;

    assign Controller.ComputeSrc        = computeSrc'('x);
    assign Controller.ResultSrc         = resultSrc'('x);
    assign Controller.TruncSrc          = truncSrc'('x);
    
    always_comb begin
        casex(funct3)
            3'b000: Controller.ConditionalPCSrc  = BEQ_C;
            3'b001: Controller.ConditionalPCSrc  = BNE_C;
            3'b100: Controller.ConditionalPCSrc  = BLT_C;
            3'b101: Controller.ConditionalPCSrc  = BGE_C;
            3'b110: Controller.ConditionalPCSrc  = BLTU_C;
            3'b111: Controller.ConditionalPCSrc  = BGEU_C;
            
            default: Controller.ConditionalPCSrc = conditionalPCSrc'('x);
            
        endcase
    end

endmodule