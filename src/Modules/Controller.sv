//James Kaden Cassidy jkc.cassidy@gmail.com 12/20/2024
`define WORD_SIZE 32
`define SIGNAL_SIZE (1        +1       +1      +1 +(WORD_SIZE/8))
//               {PCUpdate, RegWrite, MemEn, MemWrite, ByteEn}
typdef struct packed {
    
    logic[SIGNAL_SIZE-1:0] signals;

    HighLevelControl::aluOperation ALUOp;
    HighLevelControl::immSrc ImmSrc;
    HighLevelControl::aluSrcA ALUSrcA;
    HighLevelControl::aluSrcB ALUSrcB;
    HighLevelControl::resultSrc ResultSrc;
    HighLevelControl::truncSrc TruncSrc;

} controlSignals;

module controller #(
    BIT_COUNT
) (
    input[WORD_SIZE-1:0] Instr,

    output logic PCUpdate,
    output logic RegWrite,
    output HighLevelControl::immSrc ImmSrc,
    output HighLevelControl::aluSrcA ALUSrcA,
    output HighLevelControl::aluSrcB ALUSrcB,
    output HighLevelControl::aluOperation ALUOp,
    output logic MemEn,
    output logic MemWrite,
    output logic[(WORD_SIZE/8)-1:0] ByteEn,
    output HighLevelControl::resultSrc ResultSrc,
    output HighLevelControl::truncSrc TruncSrc,
);
    logic[2:0] funct3;
    logic[6:0] opcode, funct7;

    //Bus Assignments
    assign opcode = Instr[6:0];
    assign funct3 = Instr[14:12];
    assign funct7 = Instr[31:25];

    controlSignals Controller, RType, IType, ISType, LType, Stype, UType;

    //Transition to enum to simplify
    assign {PCUpdate, RegWrite, MemEn, MemWrite, ByteEn} = Controller.signals;
    assign ImmSrc = Controller.ImmSrc;
    assign ALUOp = Controller.ALUOp;
    assign ALUSrcA = Controller.AluSrcA;
    assign ALUSrcB = Controller.AluSrcB;
    assign ResultSrc = Controller.ResultSrc;
    assign TruncSrc = Controller.TruncSrc;

    //R-Type Controller
    rTypeController     RTypeController(.funct7, .funct3, .Controller(RType));
    iTypeController     ITypeController(.Immb11t0, .funct3, .Controller(IType));
    isTypeController    ISTypeController(.funct7, .funct3, .Controller(ISType));
    lTypeController     LTypeController(.funct3, .Controller(LType));
    sTypeController     STypeController(.funct3, .Controller(SType));
    uTypeController     UTypeController(.opcode, .Controller(UType));

    always_comb begin
        casex(opcode)
            7'b0110011: Controller = RType;
            7'b0010011: Controller = IType;
            7'b0010011: Controller = ISType;
            7'b0000011: Controller = LType; 
            7'b0100011: Controller = SType; 
            7'b0x10111: Controller = UType; 

            default: begin
                Controller.signals = 'x;
                Controller.ALUOp = aluOperation::NONE;
                Controller.ImmSrc = immSrc::NONE;
                Controller.TruncSrc = truncSrc::NONE;
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
    import HighLevelControl::*;

    //{PCUpdate, RegWrite, MemEn, MemWrite, ByteEn}
    assign Controller.signals = SIGNAL_SIZE'b0_1_0_0_0000;
    assign Controller.ImmSrc = 'x;
    assign Controller.ALUSrcA = aluSrcA::Rs1;
    assign Controller.ALUSrcB = aluSrcB::Rs2;
    assign Controller.ResultSrc = resultSrc::ALU;
    assign Controller.TruncSrc = truncSrc::NONE;
    
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
            
            default: assign Controller.ALUOp = aluOperation::NONE;
            
        endcase
    end

endmodule

//Operation between Rs1 and Imm put in Rd1
module iTypeController(
    input logic[2:0] funct3,

    output controlSignals Controller
);
    import HighLevelControl::*

    //{PCUpdate, RegWrite, MemEn, MemWrite, ByteEn}
    assign Controller.signals = SIGNAL_SIZE'b0_1_0_0_0000;
    assign Controller.ImmSrc = immSrc::Imm11t0;
    assign Controller.ALUSrcA = aluSrcA::Rs1;
    assign Controller.ALUSrcB = aluSrcB::Imm;
    assign Controller.ResultSrc = resultSrc::ALU;
    assign Controller.TruncSrc = truncSrc::NONE;
    
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
            
            default: Controller.ALUOp = aluOperation::NONE;
            
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

    //{PCUpdate, RegWrite, MemEn, MemWrite, ByteEn}
    assign Controller.signals = SIGNAL_SIZE'b0_1_0_0_0000;
    assign Controller.ImmSrc = immSrc::Imm4t0;
    assign Controller.ALUSrcA = aluSrcA::Rs1;
    assign Controller.ALUSrcB = aluSrcB::Imm;
    assign Controller.ResultSrc = resultSrc::ALU;
    assign Controller.TruncSrc = truncSrc::NONE;
    
    always_comb begin
        casex({funct7, funct3})
            10'b0000000_001: Controller.ALUOp = aluOperation::SLL;
            10'b0000000_101: Controller.ALUOp = aluOperation::SRL;
            10'b0100000_101: Controller.ALUOp = aluOperation::SRA;
            
            default: Controller.ALUOp = aluOperation::NONE;
            
        endcase
    end

endmodule

//Operation between Rs1 and Imm to load a value to Rd1
module lTypeController(
    input logic[2:0] funct3,

    output controlSignals Controller
);
    import HighLevelControl::*;

    //{PCUpdate, RegWrite, MemEn, MemWrite, ByteEn}
    assign Controller.signals = SIGNAL_SIZE'b0_1_1_0_0000;
    assign Controller.ImmSrc = immSrc::Imm11t0;
    assign Controller.ALUSrcA = aluSrcA::Rs1;
    assign Controller.ALUSrcB = aluSrcB::Imm;
    assign Controller.ALUOp = aluOperation::ADD;
    assign Controller.ResultSrc = resultSrc::Memory;
    
    always_comb begin
        casex(funct3)
            3'b000: Controller.TruncSrc = truncSrc::BYTE;
            3'b001: Controller.TruncSrc = truncSrc::HALF_WORD;
            3'b010: Controller.TruncSrc = truncSrc::WORD;
            3'b100: Controller.TruncSrc = truncSrc::BYTE_UNSIGNED;
            3'b101: Controller.TruncSrc = truncSrc::HALF_WORD_UNSIGNED;
            
            default: Controller.TruncSrc = truncSrc::NONE;
            
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

    assign Controller.ImmSrc = immSrc::SType;
    assign Controller.ALUSrcA = aluSrcA::Rs1;
    assign Controller.ALUSrcB = aluSrcB::Imm;
    assign Controller.ALUOp = aluOperation::ADD;
    assign Controller.ResultSrc = 'x;
    assign Controller.TruncSrc = 'x;
    
    always_comb begin
        casex(funct3)
            //{PCUpdate, RegWrite, MemEn, MemWrite, ByteEn}
            3'b000:  Controller.signals = SIGNAL_SIZE'b0_0_1_1_0001; //SB
            3'b001:  Controller.signals = SIGNAL_SIZE'b0_0_1_1_0011; //SH
            3'b010:  Controller.signals = SIGNAL_SIZE'b0_0_1_1_1111; //SW
            
            default: Controller.signals = 'x;
            
        endcase
    end
endmodule

//
module uTypeController(
    input logic[6:0] opcode,
    
    output controlSignals Controller
);
    import HighLevelControl::*;

    //{PCUpdate, RegWrite, MemEn, MemWrite, ByteEn}
    Controller.signals = SIGNAL_SIZE'b0_0_1_1_0000; 

    assign Controller.ALUSrcA = aluSrcA::OldPC;
    assign Controller.ALUSrcB = aluSrcB::Imm;
    assign Controller.ALUOp = aluOperation::ADD;
    assign Controller.ImmSrc = immSrc::UType;
    assign Controller.TruncSrc = NONE;
    
    always_comb begin
        casex(opcode)
            7'b0110111: Controller.ResultSrc = resultSrc::Rs2; //LUI
            7'b0010111: Controller.ResultSrc = resultSrc::ALU; //AUIPC
            
            default: Controller.ResultSrc = 'x;
            
        endcase
    end
endmodule