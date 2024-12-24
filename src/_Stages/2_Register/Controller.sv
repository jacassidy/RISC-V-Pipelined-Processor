//James Kaden Cassidy jkc.cassidy@gmail.com 12/20/2024
`define WORD_SIZE 32
`define SIGNAL_SIZE (1       +1      +1        +(WORD_SIZE/8))
//                {RegWrite, MemEn, MemWrite,      ByteEn}
typdef struct packed {
    
    logic[SIGNAL_SIZE-1:0]              signals;

    HighLevelControl::conditionalPCSrc  ConditionalPCSrc;

    HighLevelControl::immSrc            ImmSrc;
    HighLevelControl::updatedPCSrc      UpdatedPCSrc;

    HighLevelControl::aluSrcA           ALUSrcA;
    HighLevelControl::aluSrcB           ALUSrcB;
    HighLevelControl::aluOperation      ALUOp;

    HighLevelControl::computeSrc        ComputeSrc;
    HighLevelControl::resultSrc         ResultSrc;
    HighLevelControl::truncSrc          TruncSrc;

} controlSignals;

module controller #(
    BIT_COUNT
) (
    input   logic[WORD_SIZE-1:0]                Instr,

    output HighLevelControl::conditionalPCSrc   ConditionalPCSrc;
    output logic                                RegWrite,

    output HighLevelControl::immSrc             ImmSrc,
    output HighLevelControl::updatedPCSrc       UpdatedPCSrc,

    output HighLevelControl::aluSrcA            ALUSrcA,
    output HighLevelControl::aluSrcB            ALUSrcB,
    output HighLevelControl::aluOperation       ALUOp,

    output HighLevelControl::computeSrc         ComputeSrc,

    output logic                                MemEn,
    output logic                                MemWrite,
    output logic[(WORD_SIZE/8)-1:0]             ByteEn,

    output HighLevelControl::resultSrc          ResultSrc,
    output HighLevelControl::truncSrc           TruncSrc,
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

    assign ConditionalPCSrc        = Controller.ConditionalPCSrc;

    assign ImmSrc       = Controller.ImmSrc;
    assign UpdatedPCSrc = Controller.UpdatedPCSrc;

    assign ALUSrcA      = Controller.AluSrcA;
    assign ALUSrcB      = Controller.AluSrcB;
    assign ALUOp        = Controller.ALUOp;

    assign ComputeSrc   = Controller.ComputeSrc;
    assign ResultSrc    = Controller.ResultSrc;
    assign TruncSrc     = Controller.TruncSrc;

    //R-Type Controller
    rTypeController     RTypeController (.funct7,   .funct3,            .Controller(RType)  );
    iTypeController     ITypeController (.Immb11t0, .funct3,            .Controller(IType)  );
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

            default:    Controller = 'x;
        endcase
    end
    
endmodule

//Operation between Rs1 Rs2 and put in Rd1
module rTypeController(
    input logic[6:0] funct7,
    input logic[2:0] funct3,

    output controlSignals Controller
);
    import HighLevelControl::*;

    //{RegWrite, MemEn, MemWrite, ByteEn}
    assign Controller.signals           = SIGNAL_SIZE'b1_0_0_0000;

    assign Controller.ConditionalPCSrc  = conditionalPCSrc::PCp4;

    assign Controller.ImmSrc            = 'x;
    assign Controller.UpdatedPCSrc      = 'x;

    assign Controller.ALUSrcA           = aluSrcA::Rs1;
    assign Controller.ALUSrcB           = aluSrcB::Rs2;

    assign Controller.ComputeSrc        = computeSrc::ALU;
    assign Controller.ResultSrc         = resultSrc::Compute;
    assign Controller.TruncSrc          = truncSrc::NONE;
    
    always_comb begin
        casex({funct7, funct3})
            10'b0000000_000: Controller.ALUOp = aluOperation::ADD;
            10'b0100000_000: Controller.ALUOp = aluOperation::SUB;
            10'b0000000_110: Controller.ALUOp = aluOperation::OR;
            10'b0000000_111: Controller.ALUOp = aluOperation::AND;
            10'b0000000_100: Controller.ALUOp = aluOperation::XOR;
            10'b0000000_001: Controller.ALUOp = aluOperation::SLL;
            10'b0000000_010: Controller.ALUOp = aluOperation::SLT;
            10'b0000000_011: Controller.ALUOp = aluOperation::SLTU;
            10'b0000000_101: Controller.ALUOp = aluOperation::SRL;
            10'b0100000_101: Controller.ALUOp = aluOperation::SRA;
            
            default: Controller.ALUOp = 'x;
            
        endcase
    end

endmodule

//Operation between Rs1 and Imm put in Rd1
module iTypeController(
    input logic[2:0] funct3,

    output controlSignals Controller
);
    import HighLevelControl::*

    //{RegWrite, MemEn, MemWrite, ByteEn}
    assign Controller.signals           = SIGNAL_SIZE'b1_0_0_0000;

    assign Controller.ConditionalPCSrc  = conditionalPCSrc::PCp4;

    assign Controller.ImmSrc            = immSrc::Imm11t0;
    assign Controller.UpdatedPCSrc      = 'x;

    assign Controller.ALUSrcA           = aluSrcA::Rs1;
    assign Controller.ALUSrcB           = aluSrcB::Imm;

    assign Controller.ComputeSrc        = computeSrc::ALU;
    assign Controller.ResultSrc         = resultSrc::Compute;
    assign Controller.TruncSrc          = truncSrc::NONE;
    
    always_comb begin
        casex(funct3)
            3'b000: Controller.ALUOp = aluOperation::ADD;
            //3'b000: Controller.ALUOp = aluOperation::SUB;
            3'b110: Controller.ALUOp = aluOperation::OR;
            3'b111: Controller.ALUOp = aluOperation::AND; 
            3'b100: Controller.ALUOp = aluOperation::XOR;
            //3'b001: Controller.ALUOp = aluOperation::SLL;
            3'b010: Controller.ALUOp = aluOperation::SLT;
            3'b011: Controller.ALUOp = aluOperation::SLTU;
            //3'b101: Controller.ALUOp = aluOperation::SRL;
            //3'b101: Controller.ALUOp = aluOperation::SRA;
            
            default: Controller.ALUOp = 'x;
            
        endcase
    end

endmodule

//Shift operation between Rs1 and Imm put in Rd1
module isTypeController(
    input logic[6:0] funct7,
    input logic[2:0] funct3,

    output controlSignals Controller
);
    import HighLevelControl::*;

    //{RegWrite, MemEn, MemWrite, ByteEn}
    assign Controller.signals           = SIGNAL_SIZE'b1_0_0_0000;

    assign Controller.ConditionalPCSrc  = conditionalPCSrc::PCp4;

    assign Controller.ImmSrc            = immSrc::Imm4t0;
    assign Controller.UpdatedPCSrc      = 'x;

    assign Controller.ALUSrcA           = aluSrcA::Rs1;
    assign Controller.ALUSrcB           = aluSrcB::Imm;

    assign Controller.ComputeSrc        = computeSrc::ALU;
    assign Controller.ResultSrc         = resultSrc::Compute;
    assign Controller.TruncSrc          = truncSrc::NONE;
    
    always_comb begin
        casex({funct7, funct3})
            10'b0000000_001: Controller.ALUOp = aluOperation::SLL;
            10'b0000000_101: Controller.ALUOp = aluOperation::SRL;
            10'b0100000_101: Controller.ALUOp = aluOperation::SRA;
            
            default: Controller.ALUOp = 'x;
            
        endcase
    end

endmodule

//Operation between Rs1 and Imm to load a value to Rd1
module lTypeController(
    input logic[2:0] funct3,

    output controlSignals Controller
);
    import HighLevelControl::*;

    //{RegWrite, MemEn, MemWrite, ByteEn}
    assign Controller.signals           = SIGNAL_SIZE'b1_1_0_0000;

    assign Controller.ConditionalPCSrc  = conditionalPCSrc::PCp4;

    assign Controller.ImmSrc            = immSrc::Imm11t0;
    assign Controller.UpdatedPCSrc      = 'x;

    assign Controller.ALUSrcA           = aluSrcA::Rs1;
    assign Controller.ALUSrcB           = aluSrcB::Imm;
    assign Controller.ALUOp             = aluOperation::ADD;

    assign Controller.ComputeSrc        = computeSrc::ALU;
    assign Controller.ResultSrc         = resultSrc::Memory;
    
    always_comb begin
        casex(funct3)
            3'b000: Controller.TruncSrc = truncSrc::BYTE;
            3'b001: Controller.TruncSrc = truncSrc::HALF_WORD;
            3'b010: Controller.TruncSrc = truncSrc::WORD;
            3'b100: Controller.TruncSrc = truncSrc::BYTE_UNSIGNED;
            3'b101: Controller.TruncSrc = truncSrc::HALF_WORD_UNSIGNED;
            
            default: Controller.TruncSrc = 'x;
            
        endcase
    end

endmodule

//**** ONLY WORKS FOR 32 BIT MEMORY****// (ByteEn is 4 bits)
//Operation between Rs1 and Imm to save Rs2 to memory
module sTypeController(
    input logic[2:0] funct3,
    
    output controlSignals Controller
);
    import HighLevelControl::*;

    assign Controller.ConditionalPCSrc  = conditionalPCSrc::PCp4;

    assign Controller.ImmSrc            = immSrc::SType;
    assign Controller.UpdatedPCSrc      = 'x;

    assign Controller.ALUSrcA           = aluSrcA::Rs1;
    assign Controller.ALUSrcB           = aluSrcB::Imm;
    assign Controller.ALUOp             = aluOperation::ADD;

    assign Controller.ComputeSrc        = computeSrc::ALU;
    assign Controller.ResultSrc         = 'x;
    assign Controller.TruncSrc          = 'x;
    
    always_comb begin
        casex(funct3)
            //{RegWrite, MemEn, MemWrite, ByteEn}
            3'b000:  Controller.signals = SIGNAL_SIZE'b0_1_1_0001; //SB
            3'b001:  Controller.signals = SIGNAL_SIZE'b0_1_1_0011; //SH
            3'b010:  Controller.signals = SIGNAL_SIZE'b0_1_1_1111; //SW
            
            default: Controller.signals = 'x;
            
        endcase
    end
endmodule

//Operation with upper immediate put into Rd1
module uTypeController(
    input logic[6:0] opcode,
    
    output controlSignals Controller
);
    import HighLevelControl::*;

    //{RegWrite, MemEn, MemWrite, ByteEn}
    assign Controller.signals           = SIGNAL_SIZE'b1_0_0_0000; 

    assign Controller.ConditionalPCSrc  = conditionalPCSrc::PCp4;

    assign Controller.ImmSrc            = immSrc::UType;
    assign Controller.UpdatedPCSrc      = 'x;

    assign Controller.ResultSrc         = resultSrc::Compute;
    assign Controller.TruncSrc          = NONE;

    always_comb begin
        casex(opcode)
            7'b0110111: begin //LUI
                Controller.ALUSrcA       = 'x;
                Controller.ALUSrcB       = 'x;
                Controller.ALUOp         = 'x;
                Controller.ComputeSrc    = computeSrc::ALUOpB; 
            end
            7'b0010111: begin //AUIPC
                Controller.ALUSrcA       = aluSrcA::OldPC;
                Controller.ALUSrcB       = aluSrcB::Imm;
                Controller.ALUOp         = aluOperation::ADD;
                Controller.ComputeSrc    = computeSrc::ALU; 
            end
            
            default: begin
                Controller.ALUSrcA       = 'x;
                Controller.ALUSrcB       = 'x;
                Controller.ALUOp         = 'x;
                Controller.ComputeSrc    = 'x; 
            end
            
        endcase
    end

endmodule

//Operation PC+4 goes into Rd1 and AluOpB + PC goes into PC
module jTypeController(
    input logic[6:0] opcode,

    output controlSignals Controller
);
    import HighLevelControl::*;

    //{RegWrite, MemEn, MemWrite, ByteEn}
    assign Controller.signals       = SIGNAL_SIZE'b1_0_0_0000; 
    
    assign Controller.UpdatedPCSrc  = updatedPCSrc::PCp4;

    assign Controller.ALUOp         = 'x;

    assign Controller.ComputeSrc    = computeSrc::UpdatedPC;
    assign Controller.ResultSrc     = resultSrc::Compute;
    assign Controller.TruncSrc      = NONE;

    always_comb begin
        casex(opcode)
            7'b1101111: begin //JAL
                Controller.ConditionalPCSrc = conditionalPCSrc::PCpImm_R;

                Controller.ImmSrc           = immSrc::JType;

                Controller.ALUSrcA          = 'x;
                Controller.ALUSrcB          = 'x;
            end 

            7'b1100111: begin //JALR
                Controller.ConditionalPCSrc = conditionalPCSrc::AluAdd_C;

                Controller.ImmSrc           = immSrc::Imm11t0;

                Controller.ALUSrcA          = aluSrcA::OldPC;
                Controller.ALUSrcB          = aluSrcB::Imm;
            end
            
            
            default: begin
                Controller.ConditionalPCSrc = 'x;

                Controller.ImmSrc           = 'x;

                Controller.ALUSrcA          = 'x;
                Controller.ALUSrcB          = 'x;
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
    assign Controller.signals           = SIGNAL_SIZE'b0_0_0_0000;

    assign Controller.ImmSrc            = immSrc::BType;
    assign Controller.UpdatedPCSrc      = updatedPCSrc::PCpImm;

    assign Controller.ALUSrcA           = aluSrcA::Rs1;
    assign Controller.ALUSrcB           = aluSrcB::Rs2;
    assign Controller.ALUOp             = aluOperation::SUB;

    assign Controller.ComputeSrc        = 'x;
    assign Controller.ResultSrc         = 'x;
    assign Controller.TruncSrc          = 'x;
    
    always_comb begin
        casex(funct3)
            3'b000: Controller.ConditionalPCSrc  = conditionalPCSrc::BEQ_C;
            3'b001: Controller.ConditionalPCSrc  = conditionalPCSrc::BNE_C;
            3'b100: Controller.ConditionalPCSrc  = conditionalPCSrc::BLT_C;
            3'b101: Controller.ConditionalPCSrc  = conditionalPCSrc::BGE_C;
            3'b110: Controller.ConditionalPCSrc  = conditionalPCSrc::BLTU_C;
            3'b111: Controller.ConditionalPCSrc  = conditionalPCSrc::BGEU_C;
            
            default: Controller.ConditionalPCSrc = 'x;
            
        endcase
    end

endmodule