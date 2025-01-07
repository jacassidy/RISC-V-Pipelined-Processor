//James Kaden Cassidy jkc.cassidy@gmail.com 12/20/2024

`include "parameters.svh"

//               (1       +1      +1        +(`WORD_SIZE/8))
//                {RegWrite, MemEn, MemWrite,      ByteEn}
`define SIGNAL_SIZE 7

typedef struct packed {
    
    logic[`SIGNAL_SIZE-1:0]                 signals;

    HighLevelControl::pcSrc                 PCSrc;
    HighLevelControl::conditionalPCSrc      ConditionalPCSrc;

    HighLevelControl::immSrc                ImmSrc;
    HighLevelControl::miscSrc               MiscSrc;

    HighLevelControl::aluSrcB               AluSrcB;
    HighLevelControl::aluOperation          AluOperation;

    HighLevelControl::computeSrc            ComputeSrc;
    HighLevelControl::resultSrc             ResultSrc;
    HighLevelControl::truncSrc              TruncSrc;

} controlSignals;

function automatic void setControllerX(ref controlSignals ctrl);
    `ifndef HARDWARE_IMPLEMENATION
        `ifdef PIPELINED //if pipelining, issue can occur where registers are reset and a forward is incorrectly attempted resulting in undesired x forwarded
            //In theory this should not be a problem under a true hardware implementation
            ctrl.signals            = `SIGNAL_SIZE'b0;

            ctrl.PCSrc              = HighLevelControl::pcSrc'(0);
            ctrl.ConditionalPCSrc   = HighLevelControl::conditionalPCSrc'(0);

            ctrl.ImmSrc             = HighLevelControl::immSrc'(0);
            ctrl.MiscSrc            = HighLevelControl::miscSrc'(0);

            ctrl.AluSrcB            = HighLevelControl::aluSrcB'(0);
            ctrl.AluOperation       = HighLevelControl::aluOperation'(0);

            ctrl.ComputeSrc         = HighLevelControl::computeSrc'(0);
            ctrl.ResultSrc          = HighLevelControl::resultSrc'(0);
            ctrl.TruncSrc           = HighLevelControl::truncSrc'(0);
        `else 
            ctrl.signals            = 'x;

            ctrl.PCSrc              = HighLevelControl::pcSrc'('x);
            ctrl.ConditionalPCSrc   = HighLevelControl::conditionalPCSrc'('x);

            ctrl.ImmSrc             = HighLevelControl::immSrc'('x);
            ctrl.MiscSrc            = HighLevelControl::miscSrc'('x);

            ctrl.AluSrcB            = HighLevelControl::aluSrcB'('x);
            ctrl.AluOperation       = HighLevelControl::aluOperation'('x);

            ctrl.ComputeSrc         = HighLevelControl::computeSrc'('x);
            ctrl.ResultSrc          = HighLevelControl::resultSrc'('x);
            ctrl.TruncSrc           = HighLevelControl::truncSrc'('x);
        `endif
    `else
        ctrl.signals            = 'x;

            ctrl.PCSrc              = HighLevelControl::pcSrc'('x);
            ctrl.ConditionalPCSrc   = HighLevelControl::conditionalPCSrc'('x);

            ctrl.ImmSrc             = HighLevelControl::immSrc'('x);
            ctrl.MiscSrc            = HighLevelControl::miscSrc'('x);

            ctrl.AluSrcB            = HighLevelControl::aluSrcB'('x);
            ctrl.AluOperation       = HighLevelControl::aluOperation'('x);

            ctrl.ComputeSrc         = HighLevelControl::computeSrc'('x);
            ctrl.ResultSrc          = HighLevelControl::resultSrc'('x);
            ctrl.TruncSrc           = HighLevelControl::truncSrc'('x);
    `endif
    
endfunction

module controller #(

) (
    input   logic[`WORD_SIZE-1:0]               Instr_R,

    output HighLevelControl::pcSrc              PCSrc_R,
    output HighLevelControl::conditionalPCSrc   ConditionalPCSrc_R,
    output logic                                RegWrite_R,

    output HighLevelControl::immSrc             ImmSrc_R,
    output HighLevelControl::miscSrc            MiscSrc_R,

    output HighLevelControl::aluSrcB            AluSrcB_R,
    output HighLevelControl::aluOperation       AluOperation_R,

    output HighLevelControl::computeSrc         ComputeSrc_R,

    output logic                                MemEn_R,
    output logic                                MemWriteEn_R,
    output logic[(`BIT_COUNT/8)-1:0]            MemByteEn_R,

    output HighLevelControl::resultSrc          ResultSrc_R,
    output HighLevelControl::truncSrc           TruncSrc_R
);
    logic[2:0] funct3;
    logic[6:0] opcode, funct7;

    //Bus Assignments
    assign opcode = Instr_R[6:0];
    assign funct3 = Instr_R[14:12];
    assign funct7 = Instr_R[31:25];

    controlSignals Controller, RType, IType, LType, SType, UType, JType, BType;

    `ifdef BIT_COUNT_64
        controlSignals RWType, IWType;
    `endif 

    //Transition to enum to simplify
    assign {RegWrite_R, MemEn_R, MemWriteEn_R, MemByteEn_R[3:0]}    = Controller.signals;

    assign PCSrc_R                                                  = Controller.PCSrc;
    assign ConditionalPCSrc_R                                       = Controller.ConditionalPCSrc;

    assign ImmSrc_R                                                 = Controller.ImmSrc;
    assign MiscSrc_R                                                = Controller.MiscSrc;

    assign AluSrcB_R                                                = Controller.AluSrcB;
    assign AluOperation_R                                           = Controller.AluOperation;

    assign ComputeSrc_R                                             = Controller.ComputeSrc;
    assign ResultSrc_R                                              = Controller.ResultSrc;
    assign TruncSrc_R                                               = Controller.TruncSrc;

    //R-Type Controller
    rTypeController     RTypeController (.funct7,   .funct3,            .Controller(RType)  );
    iTypeController     ITypeController (.funct7,   .funct3,            .Controller(IType)  );
    lTypeController     LTypeController (.funct3,                       .Controller(LType)  );
    sTypeController     STypeController (.funct3,                       .Controller(SType) `ifdef BIT_COUNT_64 , .MemByteEnb7t4(MemByteEn_R[7:4]) `endif);
    uTypeController     UTypeController (.opcode,                       .Controller(UType)  );
    jTypeController     JTypeController (.opcode,                       .Controller(JType)  );
    bTypeController     BTypeController (.funct3,                       .Controller(BType)  );

    `ifdef BIT_COUNT_64
        rwTypeController     RWTypeController (.funct7, .funct3,            .Controller(RWType)  );
        iwTypeController     IWTypeController (.funct7, .funct3,            .Controller(IWType)  );
    `endif 

    always_comb begin
        

        casex(opcode)
            7'b0110011: Controller      = RType;
            7'b0010011: Controller      = IType;
            7'b0000011: Controller      = LType; 
            7'b0100011: Controller      = SType; 
            7'b0x10111: Controller      = UType; 
            7'b110x111: Controller      = JType;
            7'b1100011: Controller      = BType;

            `ifdef BIT_COUNT_64
                7'b0111011: Controller  = RWType;
                7'b0011011: Controller  = IWType;
            `endif 

            default: begin
                setControllerX(Controller);
                //{RegWrite, MemEn, MemWrite,      ByteEn}
                Controller.signals      = `SIGNAL_SIZE'b0_0_0_000;
            end
        endcase
    end
    
endmodule

//Operation between Rs1 Rs2 and put in Rd1
module rTypeController(
    input   logic[6:0]      funct7,
    input   logic[2:0]      funct3,

    output  controlSignals  Controller
);

    assign Controller.PCSrc             = HighLevelControl::PCp4_I;
    assign Controller.ConditionalPCSrc  = HighLevelControl::NO_BRANCH;

    assign Controller.ImmSrc            = HighLevelControl::immSrc'('x);
    assign Controller.MiscSrc           = HighLevelControl::miscSrc'('x);

    assign Controller.AluSrcB           = HighLevelControl::Rs2;

    assign Controller.ComputeSrc        = HighLevelControl::ALU;
    assign Controller.ResultSrc         = HighLevelControl::Compute;
    assign Controller.TruncSrc          = HighLevelControl::NO_TRUNC;
    
    always_comb begin
        //{RegWrite, MemEn, MemWrite, ByteEn}
        Controller.signals                              = `SIGNAL_SIZE'b1_0_0_0000;
        casex({funct7, funct3})
            10'b0000000_000: Controller.AluOperation    = HighLevelControl::ADD;
            10'b0100000_000: Controller.AluOperation    = HighLevelControl::SUB;
            10'b0000000_110: Controller.AluOperation    = HighLevelControl::OR;
            10'b0000000_111: Controller.AluOperation    = HighLevelControl::AND;
            10'b0000000_100: Controller.AluOperation    = HighLevelControl::XOR;
            10'b0000000_001: Controller.AluOperation    = HighLevelControl::SLL;
            10'b0000000_010: Controller.AluOperation    = HighLevelControl::SLT;
            10'b0000000_011: Controller.AluOperation    = HighLevelControl::SLTU;
            10'b0000000_101: Controller.AluOperation    = HighLevelControl::SRL;
            10'b0100000_101: Controller.AluOperation    = HighLevelControl::SRA;
            
            default: begin
                Controller.AluOperation                 = HighLevelControl::aluOperation'('x);
                Controller.signals                      = `SIGNAL_SIZE'b0;
            end
            
        endcase
    end

endmodule

//Operation between Rs1 and Imm put in Rd1
module iTypeController(
    input   logic[6:0]      funct7,
    input   logic[2:0]      funct3,

    output  controlSignals  Controller
);

    assign Controller.PCSrc             = HighLevelControl::PCp4_I;
    assign Controller.ConditionalPCSrc  = HighLevelControl::NO_BRANCH;

    assign Controller.MiscSrc           = HighLevelControl::miscSrc'('x);

    assign Controller.AluSrcB           = HighLevelControl::Imm;

    assign Controller.ComputeSrc        = HighLevelControl::ALU;
    assign Controller.ResultSrc         = HighLevelControl::Compute;
    assign Controller.TruncSrc          = HighLevelControl::NO_TRUNC;
    
    always_comb begin
        //{RegWrite, MemEn, MemWrite, ByteEn}
        Controller.signals                  = `SIGNAL_SIZE'b1_0_0_0000;
        casex(funct3)
            //normal immediate operations
            3'b000: begin
                Controller.ImmSrc           = HighLevelControl::IType;
                Controller.AluOperation     = HighLevelControl::ADD;
            end
            3'b110: begin
                Controller.ImmSrc           = HighLevelControl::IType;
                Controller.AluOperation     = HighLevelControl::OR;
            end
            3'b111: begin
                Controller.ImmSrc           = HighLevelControl::IType;
                Controller.AluOperation     = HighLevelControl::AND; 
            end
            3'b100: begin
                Controller.ImmSrc           = HighLevelControl::IType;
                Controller.AluOperation     = HighLevelControl::XOR;
            end
            3'b010: begin
                Controller.ImmSrc           = HighLevelControl::IType;
                Controller.AluOperation     = HighLevelControl::SLT;
            end
            3'b011: begin
                Controller.ImmSrc           = HighLevelControl::IType;
                Controller.AluOperation     = HighLevelControl::SLTU;
            end
            //Shift immediate operations
            3'b001: begin
                Controller.ImmSrc           = HighLevelControl::Shamt;

                if((funct7 == 7'b0000000 && `BIT_COUNT == 32) || (funct7[6:1] == 6'b000000 && `BIT_COUNT == 64)) begin

                    Controller.AluOperation = HighLevelControl::SLL;

                end else begin

                    Controller.AluOperation = HighLevelControl::aluOperation'('x);
                    Controller.signals      = `SIGNAL_SIZE'b0;

                end
            end
            3'b101: begin
                Controller.ImmSrc           = HighLevelControl::Shamt;
                
                //32 bit shamt is outside of func7, in rv64i immb5 extends into funct7
                if((funct7 == 7'b0100000 && `BIT_COUNT == 32) || (funct7[6:1] == 6'b010000 && `BIT_COUNT == 64)) begin

                    Controller.AluOperation = HighLevelControl::SRA;

                end else if((funct7 == 7'b0000000 && `BIT_COUNT == 32) || (funct7[6:1] == 6'b000000 && `BIT_COUNT == 64)) begin

                    Controller.AluOperation = HighLevelControl::SRL;

                end else begin

                    Controller.AluOperation = HighLevelControl::aluOperation'('x);
                    Controller.signals      = `SIGNAL_SIZE'b0;

                end
            end
            
            default: begin
                Controller.ImmSrc           = HighLevelControl::immSrc'('x);
                Controller.AluOperation     = HighLevelControl::aluOperation'('x);
                Controller.signals          = `SIGNAL_SIZE'b0;
            end
            
        endcase
    end

endmodule

//Operation between Rs1 and Imm to load a value to Rd1
module lTypeController(
    input logic[2:0]        funct3,

    output  controlSignals  Controller
);

    assign Controller.PCSrc             = HighLevelControl::PCp4_I;
    assign Controller.ConditionalPCSrc  = HighLevelControl::NO_BRANCH;

    assign Controller.ImmSrc            = HighLevelControl::IType;
    assign Controller.MiscSrc           = HighLevelControl::miscSrc'('x);

    assign Controller.AluSrcB           = HighLevelControl::Imm;
    assign Controller.AluOperation      = HighLevelControl::ADD;

    assign Controller.ComputeSrc        = HighLevelControl::ALU;
    assign Controller.ResultSrc         = HighLevelControl::Memory;
    
    always_comb begin
        //{RegWrite, MemEn, MemWrite, ByteEn}
        Controller.signals                  = `SIGNAL_SIZE'b1_1_0_0000;

        casex(funct3)
            3'b000: Controller.TruncSrc     = HighLevelControl::BYTE;
            3'b001: Controller.TruncSrc     = HighLevelControl::HALF_WORD;
            3'b010: Controller.TruncSrc     = HighLevelControl::WORD;
            3'b100: Controller.TruncSrc     = HighLevelControl::BYTE_UNSIGNED;
            3'b101: Controller.TruncSrc     = HighLevelControl::HALF_WORD_UNSIGNED;

            `ifdef BIT_COUNT_64
                3'b110: Controller.TruncSrc = HighLevelControl::WORD_UNSIGNED;
                3'b011: Controller.TruncSrc = HighLevelControl::NO_TRUNC;
            `endif
            
            default: begin
                Controller.TruncSrc         = HighLevelControl::truncSrc'('x);
                Controller.signals          = `SIGNAL_SIZE'b0;
            end 
            
        endcase
    end

endmodule

//Operation between Rs1 and Imm to save Rs2 to memory
module sTypeController(
    input   logic[2:0]      funct3,
    
    output  controlSignals  Controller

    `ifdef BIT_COUNT_64 , 
    output  logic[7:4]      MemByteEnb7t4
    `endif
);

    assign Controller.PCSrc             = HighLevelControl::PCp4_I;
    assign Controller.ConditionalPCSrc  = HighLevelControl::NO_BRANCH;

    assign Controller.ImmSrc            = HighLevelControl::SType;
    assign Controller.MiscSrc           = HighLevelControl::WriteData;

    assign Controller.AluSrcB           = HighLevelControl::Imm;
    assign Controller.AluOperation      = HighLevelControl::ADD;

    assign Controller.ComputeSrc        = HighLevelControl::ALU;
    assign Controller.ResultSrc         = HighLevelControl::resultSrc'('x);
    assign Controller.TruncSrc          = HighLevelControl::truncSrc'('x);
    
    always_comb begin

        `ifdef BIT_COUNT_64
            MemByteEnb7t4[7:4]          = 4'b0;
        `endif

        casex(funct3)
            //{RegWrite, MemEn, MemWrite, ByteEn}
            3'b000:  Controller.signals = `SIGNAL_SIZE'b0_1_1_0001; //SB
            3'b001:  Controller.signals = `SIGNAL_SIZE'b0_1_1_0011; //SH
            3'b010:  Controller.signals = `SIGNAL_SIZE'b0_1_1_1111; //SW

            `ifdef BIT_COUNT_64
                3'b011: begin
                    Controller.signals  = `SIGNAL_SIZE'b0_1_1_1111; //SD
                    MemByteEnb7t4[7:4]  = 4'hf;                     //SD
                end
            `endif
            
            default: Controller.signals = `SIGNAL_SIZE'b0;

        endcase
    end
endmodule

//Operation with upper immediate put into Rd1
module uTypeController(
    input   logic[6:0]      opcode,
    
    output  controlSignals  Controller
);

    assign Controller.PCSrc             = HighLevelControl::PCp4_I;
    assign Controller.ConditionalPCSrc  = HighLevelControl::NO_BRANCH;

    assign Controller.AluSrcB           = HighLevelControl::aluSrcB'('x);
    assign Controller.AluOperation      = HighLevelControl::aluOperation'('x);

    assign Controller.ImmSrc            = HighLevelControl::UType;

    assign Controller.ComputeSrc        = HighLevelControl::Misc; 
    assign Controller.ResultSrc         = HighLevelControl::Compute;
    assign Controller.TruncSrc          = HighLevelControl::NO_TRUNC;

    always_comb begin
        //{RegWrite, MemEn, MemWrite, ByteEn}
        Controller.signals                  = `SIGNAL_SIZE'b1_0_0_0000; 

        casex(opcode)
            7'b0110111: Controller.MiscSrc  = HighLevelControl::LoadImm;  //LUI
            7'b0010111: Controller.MiscSrc  = HighLevelControl::PCpImm;   //AUIPC
            
            default:    begin
                Controller.MiscSrc          = HighLevelControl::miscSrc'('x); 
                Controller.signals          = `SIGNAL_SIZE'b0;
            end
            
        endcase
    end

endmodule

//Operation PC+4 goes into Rd1 and AluOpB + PC goes into PC
module jTypeController(
    input   logic[6:0]      opcode,

    output  controlSignals  Controller
);

    assign Controller.ConditionalPCSrc  = HighLevelControl::NO_BRANCH;
    
    assign Controller.MiscSrc           = HighLevelControl::PCp4;

    assign Controller.AluOperation      = HighLevelControl::aluOperation'('x);

    assign Controller.ComputeSrc        = HighLevelControl::Misc;
    assign Controller.ResultSrc         = HighLevelControl::Compute;
    assign Controller.TruncSrc          = HighLevelControl::NO_TRUNC;

    always_comb begin
        //{RegWrite, MemEn, MemWrite, ByteEn}
        Controller.signals                  = `SIGNAL_SIZE'b1_0_0_0000; 
        casex(opcode)
            7'b1101111: begin //JAL
                Controller.PCSrc            = HighLevelControl::Jump_R;
    
                Controller.ImmSrc           = HighLevelControl::JType;

                Controller.AluSrcB          = HighLevelControl::aluSrcB'('x);
            end 

            7'b1100111: begin //JALR
                Controller.PCSrc            = HighLevelControl::Jump_C;

                Controller.ImmSrc           = HighLevelControl::IType;

                Controller.AluSrcB          = HighLevelControl::Imm;
            end
            
            
            default: begin
                Controller.PCSrc            = HighLevelControl::pcSrc'('x);

                Controller.ImmSrc           = HighLevelControl::immSrc'('x);

                Controller.AluSrcB          = HighLevelControl::aluSrcB'('x);

                Controller.signals          = `SIGNAL_SIZE'b0;
            end
            
        endcase
    end

endmodule

//Operation between Rs1 and Rs2 to determine if Imm + PC goes into PC
module bTypeController(
    input   logic[2:0]      funct3,

    output  controlSignals  Controller
);
    assign Controller.PCSrc             = HighLevelControl::Branch_C;

    assign Controller.ImmSrc            = HighLevelControl::BType;
    assign Controller.MiscSrc           = HighLevelControl::PCpImm;

    assign Controller.AluSrcB           = HighLevelControl::Rs2;
    assign Controller.AluOperation      = HighLevelControl::SUB;

    assign Controller.ComputeSrc        = HighLevelControl::computeSrc'('x);
    assign Controller.ResultSrc         = HighLevelControl::resultSrc'('x);
    assign Controller.TruncSrc          = HighLevelControl::truncSrc'('x);
    
    always_comb begin
        //{RegWrite, MemEn, MemWrite, ByteEn}
        Controller.signals                      = `SIGNAL_SIZE'b0_0_0_0000;
        
        casex(funct3)
            3'b000: Controller.ConditionalPCSrc = HighLevelControl::BEQ_C;
            3'b001: Controller.ConditionalPCSrc = HighLevelControl::BNE_C;
            3'b100: Controller.ConditionalPCSrc = HighLevelControl::BLT_C;
            3'b101: Controller.ConditionalPCSrc = HighLevelControl::BGE_C;
            3'b110: Controller.ConditionalPCSrc = HighLevelControl::BLTU_C;
            3'b111: Controller.ConditionalPCSrc = HighLevelControl::BGEU_C;
            
            default: begin
                Controller.ConditionalPCSrc     = HighLevelControl::conditionalPCSrc'('x);
                Controller.signals              = `SIGNAL_SIZE'b0;
            end
            
        endcase
    end

endmodule

//////////****************RV64I*******************//////////
`ifdef BIT_COUNT_64
//32-Bit operation between Rs1 Rs2 and put in Rd1
module rwTypeController(
    input   logic[6:0]      funct7,
    input   logic[2:0]      funct3,

    output  controlSignals  Controller
);
    assign Controller.PCSrc             = HighLevelControl::PCp4_I;
    assign Controller.ConditionalPCSrc  = HighLevelControl::NO_BRANCH;

    assign Controller.ImmSrc            = HighLevelControl::immSrc'('x);
    assign Controller.MiscSrc           = HighLevelControl::miscSrc'('x);

    assign Controller.AluSrcB           = HighLevelControl::Rs2;

    assign Controller.ComputeSrc        = HighLevelControl::ALU;
    assign Controller.ResultSrc         = HighLevelControl::Compute;
    assign Controller.TruncSrc          = HighLevelControl::NO_TRUNC;
    
    always_comb begin
        //{RegWrite, MemEn, MemWrite, ByteEn}
        Controller.signals                              = `SIGNAL_SIZE'b1_0_0_0000;

        casex({funct7, funct3})
            10'b0000000_000: Controller.AluOperation    = HighLevelControl::ADDW;
            10'b0100000_000: Controller.AluOperation    = HighLevelControl::SUBW;
            
            10'b0000000_001: Controller.AluOperation    = HighLevelControl::SLLW;
            10'b0000000_101: Controller.AluOperation    = HighLevelControl::SRLW;
            10'b0100000_101: Controller.AluOperation    = HighLevelControl::SRAW;
            
            default: begin
                Controller.AluOperation                 = HighLevelControl::aluOperation'('x);
                Controller.signals                      = `SIGNAL_SIZE'b0;
            end
            
        endcase
    end

endmodule

//32-Bit operation between Rs1 and Imm put in Rd1
module iwTypeController(
    input   logic[6:0]      funct7,
    input   logic[2:0]      funct3,

    output  controlSignals  Controller
);
    assign Controller.PCSrc             = HighLevelControl::PCp4_I;
    assign Controller.ConditionalPCSrc  = HighLevelControl::NO_BRANCH;

    assign Controller.MiscSrc           = HighLevelControl::miscSrc'('x);

    assign Controller.AluSrcB           = HighLevelControl::Imm;

    assign Controller.ComputeSrc        = HighLevelControl::ALU;
    assign Controller.ResultSrc         = HighLevelControl::Compute;
    assign Controller.TruncSrc          = HighLevelControl::NO_TRUNC;
    
    always_comb begin
        //{RegWrite, MemEn, MemWrite, ByteEn}
        Controller.signals                  = `SIGNAL_SIZE'b1_0_0_0000;

        casex(funct3)
            //normal immediate operations
            3'b000: begin
                Controller.ImmSrc           = HighLevelControl::IType;
                Controller.AluOperation     = HighLevelControl::ADDW;
            end
            
            //Shift immediate operations
            3'b001: begin
                Controller.ImmSrc           = HighLevelControl::Shamt;
                Controller.AluOperation     = HighLevelControl::SLLW;
            end
            3'b101: begin
                Controller.ImmSrc           = HighLevelControl::Shamt;

                if(funct7 == 7'b0100000) begin

                    Controller.AluOperation = HighLevelControl::SRAW;

                end else if(funct7 == 7'b0000000) begin

                    Controller.AluOperation = HighLevelControl::SRLW;

                end else begin

                    Controller.AluOperation = HighLevelControl::aluOperation'('x);
                    Controller.signals      = `SIGNAL_SIZE'b0;

                end
            end
            
            default: begin
                Controller.ImmSrc           = HighLevelControl::immSrc'('x);
                Controller.AluOperation     = HighLevelControl::aluOperation'('x);
                Controller.signals          = `SIGNAL_SIZE'b0;
            end
            
        endcase
    end

endmodule

`endif