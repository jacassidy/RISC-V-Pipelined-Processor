//James Kaden Cassidy jkc.cassidy@gmail.com 12/20/2024

`include "parameters.svh"

typedef struct packed {

    logic                                   RegWrite;
    logic                                   MemEn;
    logic                                   MemWriteEn;

    HighLevelControl::pcSrc                 PCSrc;
    HighLevelControl::conditionalPCSrc      ConditionalPCSrc;

    HighLevelControl::immSrc                ImmSrcA;
    HighLevelControl::immSrc                ImmSrcB;
    HighLevelControl::passthroughSrc        PassthroughSrc;

    HighLevelControl::aluSrc                AluSrcA;
    HighLevelControl::aluSrc                AluSrcB;
    HighLevelControl::aluOperation          AluOperation;

    HighLevelControl::computeSrc            ComputeSrc;
    HighLevelControl::storeType             StoreType;
    HighLevelControl::resultSrc             ResultSrc;
    HighLevelControl::truncType             TruncType;

    `ifdef ZICSR
    logic                                   CSREn;
    HighLevelControl::csrOp                 CSROp;
    `endif

} controlSignals;

function automatic controlSignals ControllerDefault();

    controlSignals ctrl;

    ctrl.RegWrite           = 1'b0;
    ctrl.MemEn              = 1'b0;
    ctrl.MemWriteEn         = 1'b0;

    ctrl.PCSrc              = HighLevelControl::PCp4_I;
    ctrl.ConditionalPCSrc   = HighLevelControl::NO_BRANCH;

    ctrl.ImmSrcA            = HighLevelControl::immSrc'('x);
    ctrl.ImmSrcB            = HighLevelControl::immSrc'('x);
    ctrl.PassthroughSrc     = HighLevelControl::passthroughSrc'('x);

    ctrl.AluSrcA            = HighLevelControl::Rs;
    ctrl.AluSrcB            = HighLevelControl::Rs;
    ctrl.AluOperation       = HighLevelControl::aluOperation'('x);

    ctrl.ComputeSrc         = HighLevelControl::computeSrc'('x);
    ctrl.StoreType          = HighLevelControl::storeType'('x);
    ctrl.ResultSrc          = HighLevelControl::Compute;
    ctrl.TruncType          = HighLevelControl::NO_TRUNC;

    `ifdef ZICSR
    ctrl.CSREn              = 1'b0;
    ctrl.CSROp              = HighLevelControl::csrOp'('x);;
    `endif

    return ctrl;

endfunction

module controller (
    input   logic[`WORD_SIZE-1:0]               Instr_R,

    output HighLevelControl::pcSrc              PCSrc_R,
    output HighLevelControl::conditionalPCSrc   ConditionalPCSrc_R,
    output logic                                RegWrite_R,

    output HighLevelControl::immSrc             ImmSrcA_R,
    output HighLevelControl::immSrc             ImmSrcB_R,
    output HighLevelControl::passthroughSrc     PassthroughSrc_R,

    output HighLevelControl::aluSrc             AluSrcA_R,
    output HighLevelControl::aluSrc             AluSrcB_R,
    output HighLevelControl::aluOperation       AluOperation_R,

    output HighLevelControl::computeSrc         ComputeSrc_R,

    output logic                                MemEn_R,
    output logic                                MemWriteEn_R,
    output HighLevelControl::storeType          StoreType_R,

    output HighLevelControl::resultSrc          ResultSrc_R,
    output HighLevelControl::truncType          TruncType_R

    `ifdef ZICSR
    ,
    output logic                                CSREn_R,
    output HighLevelControl::csrOp              CSROp_R
    `endif
);
    logic[2:0] funct3;
    logic[6:0] opcode, funct7;
    logic[4:0] rs1, rd;

    //Bus Assignments
    assign opcode = Instr_R[ 6:0 ];
    assign funct3 = Instr_R[14:12];
    assign funct7 = Instr_R[31:25];
    assign rs1    = Instr_R[19:15];
    assign rd     = Instr_R[11:7 ];

    controlSignals Controller, RType, IType, LType, SType, UType, JType, BType;

    `ifdef XLEN_64
        controlSignals RWType, IWType;
    `endif

    `ifdef ZICSR
        controlSignals CSRType;
    `endif

    // Transition to enum to simplify
    assign RegWrite_R                                               = Controller.RegWrite;
    assign MemEn_R                                                  = Controller.MemEn;
    assign MemWriteEn_R                                             = Controller.MemWriteEn;

    assign PCSrc_R                                                  = Controller.PCSrc;
    assign ConditionalPCSrc_R                                       = Controller.ConditionalPCSrc;

    assign ImmSrcA_R                                                = Controller.ImmSrcA;
    assign ImmSrcB_R                                                = Controller.ImmSrcB;
    assign PassthroughSrc_R                                         = Controller.PassthroughSrc;

    assign AluSrcA_R                                                = Controller.AluSrcA;
    assign AluSrcB_R                                                = Controller.AluSrcB;
    assign AluOperation_R                                           = Controller.AluOperation;

    assign ComputeSrc_R                                             = Controller.ComputeSrc;
    assign StoreType_R                                              = Controller.StoreType;
    assign ResultSrc_R                                              = Controller.ResultSrc;
    assign TruncType_R                                              = Controller.TruncType;

    `ifdef ZICSR
    assign CSREn_R                                                  = Controller.CSREn;
    assign CSROp_R                                                  = Controller.CSROp;
    `endif

    // Controller Types
    rTypeController     RTypeController (.funct7,   .funct3,            .Controller(RType)  );
    iTypeController     ITypeController (.funct7,   .funct3,            .Controller(IType)  );
    lTypeController     LTypeController (.funct3,                       .Controller(LType)  );
    sTypeController     STypeController (.funct3,                       .Controller(SType)  );
    uTypeController     UTypeController (.opcode,                       .Controller(UType)  );
    jTypeController     JTypeController (.opcode,                       .Controller(JType)  );
    bTypeController     BTypeController (.funct3,                       .Controller(BType)  );

    `ifdef XLEN_64
        rwTypeController     RWTypeController (.funct7, .funct3,            .Controller(RWType)  );
        iwTypeController     IWTypeController (.funct7, .funct3,            .Controller(IWType)  );
    `endif

    `ifdef ZICSR
        csrTypeController    CSRTypeController (.rs1, .rd, .funct3,         .Controller(CSRType) );
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

            `ifdef XLEN_64
                7'b0111011: Controller  = RWType;
                7'b0011011: Controller  = IWType;
            `endif

            `ifdef ZICSR
                7'b1110011: Controller  = CSRType;
            `endif

            default: begin // instruction not supported
                Controller = ControllerDefault();
                `ifdef DEBUG_PRINT
                if (Instr_R !== 'x && Instr_R !== 0) begin
                    $display("Instruction not implemented: Machine Code (%h)", Instr_R);
                    //$finish(-1);
                end
                `endif
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

    always_comb begin

        Controller                      = ControllerDefault();

        Controller.RegWrite             = 1'b1;
        Controller.MemEn                = 1'b0;
        Controller.MemWriteEn           = 1'b0;

        Controller.PCSrc                = HighLevelControl::PCp4_I;
        Controller.ConditionalPCSrc     = HighLevelControl::NO_BRANCH;

        // Controller.ImmSrcB           = HighLevelControl::immSrc'('x);
        // Controller.PassthroughSrc    = HighLevelControl::passthroughSrc'('x);

        Controller.AluSrcB              = HighLevelControl::Rs;

        Controller.ComputeSrc           = HighLevelControl::ALU;
        // Controller.StoreType         = HighLevelControl::storeType'('x);
        Controller.ResultSrc            = HighLevelControl::Compute;
        Controller.TruncType            = HighLevelControl::NO_TRUNC;

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
                Controller.RegWrite                     = 1'b0;
                Controller.MemEn                        = 1'b0;
                Controller.MemWriteEn                   = 1'b0;
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

    always_comb begin

        Controller                      = ControllerDefault();

        Controller.RegWrite             = 1'b1;
        Controller.MemEn                = 1'b0;
        Controller.MemWriteEn           = 1'b0;

        Controller.PCSrc                = HighLevelControl::PCp4_I;
        Controller.ConditionalPCSrc     = HighLevelControl::NO_BRANCH;

        // Controller.PassthroughSrc    = HighLevelControl::passthroughSrc'('x);

        Controller.AluSrcB              = HighLevelControl::Imm;

        Controller.ComputeSrc           = HighLevelControl::ALU;
        // Controller.StoreType         = HighLevelControl::storeType'('x);
        Controller.ResultSrc            = HighLevelControl::Compute;
        Controller.TruncType            = HighLevelControl::NO_TRUNC;

        casex(funct3)
            //normal immediate operations
            3'b000: begin
                Controller.ImmSrcB          = HighLevelControl::IType;
                Controller.AluOperation     = HighLevelControl::ADD;
            end
            3'b110: begin
                Controller.ImmSrcB          = HighLevelControl::IType;
                Controller.AluOperation     = HighLevelControl::OR;
            end
            3'b111: begin
                Controller.ImmSrcB          = HighLevelControl::IType;
                Controller.AluOperation     = HighLevelControl::AND;
            end
            3'b100: begin
                Controller.ImmSrcB          = HighLevelControl::IType;
                Controller.AluOperation     = HighLevelControl::XOR;
            end
            3'b010: begin
                Controller.ImmSrcB          = HighLevelControl::IType;
                Controller.AluOperation     = HighLevelControl::SLT;
            end
            3'b011: begin
                Controller.ImmSrcB          = HighLevelControl::IType;
                Controller.AluOperation     = HighLevelControl::SLTU;
            end
            //Shift immediate operations
            3'b001: begin
                Controller.ImmSrcB          = HighLevelControl::Shamt;

                if((funct7 == 7'b0000000 && `XLEN == 32) || (funct7[6:1] == 6'b000000 && `XLEN == 64)) begin

                    Controller.AluOperation = HighLevelControl::SLL;

                end else begin

                    Controller.AluOperation = HighLevelControl::aluOperation'('x);
                    Controller.RegWrite     = 1'b0;
                    Controller.MemEn        = 1'b0;
                    Controller.MemWriteEn   = 1'b0;

                end
            end
            3'b101: begin
                Controller.ImmSrcB          = HighLevelControl::Shamt;

                //32 bit shamt is outside of func7, in rv64i immb5 extends into funct7
                if((funct7 == 7'b0100000 && `XLEN == 32) || (funct7[6:1] == 6'b010000 && `XLEN == 64)) begin

                    Controller.AluOperation = HighLevelControl::SRA;

                end else if((funct7 == 7'b0000000 && `XLEN == 32) || (funct7[6:1] == 6'b000000 && `XLEN == 64)) begin

                    Controller.AluOperation = HighLevelControl::SRL;

                end else begin

                    Controller.AluOperation = HighLevelControl::aluOperation'('x);
                    Controller.RegWrite     = 1'b0;
                    Controller.MemEn        = 1'b0;
                    Controller.MemWriteEn   = 1'b0;

                end
            end

            default: begin
                Controller.ImmSrcB          = HighLevelControl::immSrc'('x);
                Controller.AluOperation     = HighLevelControl::aluOperation'('x);
                Controller.RegWrite         = 1'b0;
                Controller.MemEn            = 1'b0;
                Controller.MemWriteEn       = 1'b0;
            end

        endcase
    end

endmodule

//Operation between Rs1 and Imm to load a value to Rd1
module lTypeController(
    input logic[2:0]        funct3,

    output  controlSignals  Controller
);

    always_comb begin

        Controller                      = ControllerDefault();

        Controller.RegWrite             = 1'b1;
        Controller.MemEn                = 1'b1;
        Controller.MemWriteEn           = 1'b0;

        Controller.PCSrc                = HighLevelControl::PCp4_I;
        Controller.ConditionalPCSrc     = HighLevelControl::NO_BRANCH;

        Controller.ImmSrcB              = HighLevelControl::IType;
        // Controller.PassthroughSrc    = HighLevelControl::passthroughSrc'('x);

        Controller.AluSrcB              = HighLevelControl::Imm;
        Controller.AluOperation         = HighLevelControl::ADD;

        Controller.ComputeSrc           = HighLevelControl::ALU;
        // Controller.StoreType         = HighLevelControl::storeType'('x);
        Controller.ResultSrc            = HighLevelControl::Memory;

        casex(funct3)
            3'b000: Controller.TruncType        = HighLevelControl::BYTE;
            3'b001: Controller.TruncType        = HighLevelControl::HALF_WORD;
            3'b010: Controller.TruncType        = HighLevelControl::WORD;
            3'b100: Controller.TruncType        = HighLevelControl::BYTE_UNSIGNED;
            3'b101: Controller.TruncType        = HighLevelControl::HALF_WORD_UNSIGNED;

            `ifdef XLEN_64
                3'b110: Controller.TruncType    = HighLevelControl::WORD_UNSIGNED;
                3'b011: Controller.TruncType    = HighLevelControl::NO_TRUNC;
            `endif

            default: begin
                Controller.TruncType            = HighLevelControl::truncType'('x);
                Controller.RegWrite             = 1'b0;
                Controller.MemEn                = 1'b0;
                Controller.MemWriteEn           = 1'b0;
            end

        endcase
    end

endmodule

//Operation between Rs1 and Imm to save Rs2 to memory
module sTypeController(
    input   logic[2:0]      funct3,

    output  controlSignals  Controller
);

    always_comb begin

        Controller                      = ControllerDefault();

        Controller.RegWrite             = 1'b0;
        Controller.MemEn                = 1'b1;
        Controller.MemWriteEn           = 1'b1;

        Controller.PCSrc                = HighLevelControl::PCp4_I;
        Controller.ConditionalPCSrc     = HighLevelControl::NO_BRANCH;

        Controller.ImmSrcB              = HighLevelControl::SType;
        Controller.PassthroughSrc       = HighLevelControl::WriteData;

        Controller.AluSrcB              = HighLevelControl::Imm;
        Controller.AluOperation         = HighLevelControl::ADD;

        Controller.ComputeSrc           = HighLevelControl::ALU;
        // Controller.ResultSrc         = HighLevelControl::resultSrc'('x);
        // Controller.TruncType         = HighLevelControl::truncType'('x);

        casex(funct3)
            3'b000:  Controller.StoreType   = HighLevelControl::Store_Byte;         //SB
            3'b001:  Controller.StoreType   = HighLevelControl::Store_Half_Word;    //SH
            3'b010:  Controller.StoreType   = HighLevelControl::Store_Word;         //SW

            `ifdef XLEN_64
            3'b011:  Controller.StoreType   = HighLevelControl::Store_Double_Word;  //SD
            `endif

            default: Controller.StoreType   = HighLevelControl::storeType'('x);

        endcase
    end
endmodule

//Operation with upper immediate put into Rd1
module uTypeController(
    input   logic[6:0]      opcode,

    output  controlSignals  Controller
);

    always_comb begin

        Controller                      = ControllerDefault();

        Controller.RegWrite             = 1'b1;
        Controller.MemEn                = 1'b0;
        Controller.MemWriteEn           = 1'b0;

        Controller.PCSrc                = HighLevelControl::PCp4_I;
        Controller.ConditionalPCSrc     = HighLevelControl::NO_BRANCH;

        // Controller.AluSrcB           = HighLevelControl::aluSrc'('x);
        // Controller.AluOperation      = HighLevelControl::aluOperation'('x);

        Controller.ImmSrcB              = HighLevelControl::UType;

        Controller.ComputeSrc           = HighLevelControl::Passthrough;
        // Controller.StoreType         = HighLevelControl::storeType'('x);
        Controller.ResultSrc            = HighLevelControl::Compute;
        Controller.TruncType            = HighLevelControl::NO_TRUNC;

        casex(opcode)
            7'b0110111: Controller.PassthroughSrc   = HighLevelControl::LoadImm;  //LUI
            7'b0010111: Controller.PassthroughSrc   = HighLevelControl::PCpImm;   //AUIPC

            default:    begin
                Controller.PassthroughSrc           = HighLevelControl::passthroughSrc'('x);
                Controller.RegWrite                 = 1'b0;
                Controller.MemEn                    = 1'b0;
                Controller.MemWriteEn               = 1'b0;
            end

        endcase
    end

endmodule

//Operation PC+4 goes into Rd1 and AluOpB + PC goes into PC
module jTypeController(
    input   logic[6:0]      opcode,

    output  controlSignals  Controller
);

    always_comb begin

        Controller                      = ControllerDefault();

        Controller.RegWrite             = 1'b1;
        Controller.MemEn                = 1'b0;
        Controller.MemWriteEn           = 1'b0;

        Controller.ConditionalPCSrc     = HighLevelControl::NO_BRANCH;

        Controller.PassthroughSrc       = HighLevelControl::PCp4;

        // Controller.AluOperation      = HighLevelControl::aluOperation'('x);

        Controller.ComputeSrc           = HighLevelControl::Passthrough;
        // Controller.StoreType         = HighLevelControl::storeType'('x);
        Controller.ResultSrc            = HighLevelControl::Compute;
        Controller.TruncType            = HighLevelControl::NO_TRUNC;

        casex(opcode)
            7'b1101111: begin //JAL
                Controller.PCSrc            = HighLevelControl::Jump_R;

                Controller.ImmSrcB          = HighLevelControl::JType;

                Controller.AluSrcB          = HighLevelControl::aluSrc'('x);
            end

            7'b1100111: begin //JALR
                Controller.PCSrc            = HighLevelControl::Jump_C;

                Controller.ImmSrcB          = HighLevelControl::IType;

                Controller.AluSrcB          = HighLevelControl::Imm;
            end


            default: begin
                Controller.PCSrc            = HighLevelControl::pcSrc'('x);

                Controller.ImmSrcB          = HighLevelControl::immSrc'('x);

                Controller.AluSrcB          = HighLevelControl::aluSrc'('x);

                Controller.RegWrite         = 1'b0;
                Controller.MemEn            = 1'b0;
                Controller.MemWriteEn       = 1'b0;
            end

        endcase
    end

endmodule

//Operation between Rs1 and Rs2 to determine if Imm + PC goes into PC
module bTypeController(
    input   logic[2:0]      funct3,

    output  controlSignals  Controller
);

    always_comb begin

        Controller                      = ControllerDefault();

        Controller.RegWrite             = 1'b0;
        Controller.MemEn                = 1'b0;
        Controller.MemWriteEn           = 1'b0;

        Controller.PCSrc                = HighLevelControl::Branch_C;

        Controller.ImmSrcB              = HighLevelControl::BType;
        Controller.PassthroughSrc       = HighLevelControl::PCpImm;

        Controller.AluSrcB              = HighLevelControl::Rs;
        Controller.AluOperation         = HighLevelControl::SUB;

        // Controller.ComputeSrc        = HighLevelControl::computeSrc'('x);
        // Controller.StoreType         = HighLevelControl::storeType'('x);
        // Controller.ResultSrc         = HighLevelControl::resultSrc'('x);
        // Controller.TruncType         = HighLevelControl::truncType'('x);

        casex(funct3)
            3'b000: Controller.ConditionalPCSrc = HighLevelControl::BEQ_C;
            3'b001: Controller.ConditionalPCSrc = HighLevelControl::BNE_C;
            3'b100: Controller.ConditionalPCSrc = HighLevelControl::BLT_C;
            3'b101: Controller.ConditionalPCSrc = HighLevelControl::BGE_C;
            3'b110: Controller.ConditionalPCSrc = HighLevelControl::BLTU_C;
            3'b111: Controller.ConditionalPCSrc = HighLevelControl::BGEU_C;

            default: begin
                Controller.ConditionalPCSrc     = HighLevelControl::conditionalPCSrc'('x);
                Controller.RegWrite             = 1'b0;
                Controller.MemEn                = 1'b0;
                Controller.MemWriteEn           = 1'b0;
            end

        endcase
    end

endmodule

//////////****************RV64I*******************//////////
`ifdef XLEN_64
//32-Bit operation between Rs1 Rs2 and put in Rd1
module rwTypeController(
    input   logic[6:0]      funct7,
    input   logic[2:0]      funct3,

    output  controlSignals  Controller
);

    always_comb begin
        Controller                      = ControllerDefault();

        Controller.RegWrite             = 1'b1;
        Controller.MemEn                = 1'b0;
        Controller.MemWriteEn           = 1'b0;

        Controller.PCSrc                = HighLevelControl::PCp4_I;
        Controller.ConditionalPCSrc     = HighLevelControl::NO_BRANCH;

        // Controller.ImmSrcB           = HighLevelControl::immSrc'('x);
        // Controller.PassthroughSrc    = HighLevelControl::passthroughSrc'('x);

        Controller.AluSrcB              = HighLevelControl::Rs;

        Controller.ComputeSrc           = HighLevelControl::ALU;
        // Controller.StoreType         = HighLevelControl::storeType'('x);
        Controller.ResultSrc            = HighLevelControl::Compute;
        Controller.TruncType            = HighLevelControl::NO_TRUNC;

        casex({funct7, funct3})
            10'b0000000_000: Controller.AluOperation    = HighLevelControl::ADDW;
            10'b0100000_000: Controller.AluOperation    = HighLevelControl::SUBW;

            10'b0000000_001: Controller.AluOperation    = HighLevelControl::SLLW;
            10'b0000000_101: Controller.AluOperation    = HighLevelControl::SRLW;
            10'b0100000_101: Controller.AluOperation    = HighLevelControl::SRAW;

            default: begin
                Controller.AluOperation                 = HighLevelControl::aluOperation'('x);
                Controller.RegWrite                     = 1'b0;
                Controller.MemEn                        = 1'b0;
                Controller.MemWriteEn                   = 1'b0;
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

    always_comb begin

        Controller                      = ControllerDefault();

        Controller.RegWrite             = 1'b1;
        Controller.MemEn                = 1'b0;
        Controller.MemWriteEn           = 1'b0;

        Controller.PCSrc                = HighLevelControl::PCp4_I;
        Controller.ConditionalPCSrc     = HighLevelControl::NO_BRANCH;

        // Controller.PassthroughSrc    = HighLevelControl::passthroughSrc'('x);

        Controller.AluSrcB              = HighLevelControl::Imm;

        Controller.ComputeSrc           = HighLevelControl::ALU;
        // Controller.StoreType         = HighLevelControl::storeType'('x);
        Controller.ResultSrc            = HighLevelControl::Compute;
        Controller.TruncType            = HighLevelControl::NO_TRUNC;

        casex(funct3)
            //normal immediate operations
            3'b000: begin
                Controller.ImmSrcB          = HighLevelControl::IType;
                Controller.AluOperation     = HighLevelControl::ADDW;
            end

            //Shift immediate operations
            3'b001: begin
                Controller.ImmSrcB          = HighLevelControl::Shamt;
                Controller.AluOperation     = HighLevelControl::SLLW;
            end
            3'b101: begin
                Controller.ImmSrcB          = HighLevelControl::Shamt;

                if(funct7 == 7'b0100000) begin

                    Controller.AluOperation = HighLevelControl::SRAW;

                end else if(funct7 == 7'b0000000) begin

                    Controller.AluOperation = HighLevelControl::SRLW;

                end else begin

                    Controller.AluOperation = HighLevelControl::aluOperation'('x);
                    Controller.RegWrite     = 1'b0;
                    Controller.MemEn        = 1'b0;
                    Controller.MemWriteEn   = 1'b0;

                end
            end

            default: begin
                Controller.ImmSrcB          = HighLevelControl::immSrc'('x);
                Controller.AluOperation     = HighLevelControl::aluOperation'('x);
                Controller.RegWrite         = 1'b0;
                Controller.MemEn            = 1'b0;
                Controller.MemWriteEn       = 1'b0;
            end

        endcase
    end

endmodule

`endif

`ifdef ZICSR
// CSR Read write atomic operations
module csrTypeController(
    input   logic[4:0]      rs1,
    input   logic[4:0]      rd,
    input   logic[2:0]      funct3,

    output  controlSignals  Controller
);

    always_comb begin

        Controller                      = ControllerDefault();

        Controller.RegWrite             = 1'b1;
        Controller.MemEn                = 1'b0;
        Controller.MemWriteEn           = 1'b0;

        Controller.ImmSrcB              = HighLevelControl::CSRAdrType;
        Controller.PassthroughSrc       = HighLevelControl::passthroughSrc'('x);

        Controller.AluSrcB              = HighLevelControl::Imm;
        Controller.AluOperation         = HighLevelControl::aluOperation'('x);

        Controller.ComputeSrc           = HighLevelControl::CSRRead;
        Controller.StoreType            = HighLevelControl::storeType'('x);
        Controller.ResultSrc            = HighLevelControl::Compute;
        Controller.TruncType            = HighLevelControl::NO_TRUNC;

        Controller.CSREn                = 1'b1;

        casex (funct3)
            3'b001: begin // CSSRW
                Controller.RegWrite     = rd != '0;
                Controller.CSROp        = HighLevelControl::Write;
                Controller.AluSrcA      = HighLevelControl::Rs;
            end
            3'b101: begin // CSSRWI
                Controller.RegWrite     = rd != '0;
                Controller.CSROp        = HighLevelControl::Write;
                Controller.ImmSrcA      = HighLevelControl::CSRValType;
                Controller.AluSrcA      = HighLevelControl::Imm;
            end
            3'b010: begin // CSSRS
                Controller.CSROp        = rs1 != '0 ? HighLevelControl::Set : HighLevelControl::Read;
                Controller.AluSrcA      = HighLevelControl::Rs;
            end
            3'b110: begin // CSSRSI
                Controller.CSROp        = rs1 != '0 ? HighLevelControl::Set : HighLevelControl::Read;
                Controller.ImmSrcA      = HighLevelControl::CSRValType;
                Controller.AluSrcA      = HighLevelControl::Imm;
            end
            3'b011: begin // CSSRC
                Controller.CSROp        = rs1 != '0 ? HighLevelControl::Clear : HighLevelControl::Read;
                Controller.AluSrcA      = HighLevelControl::Rs;
            end
            3'b111: begin // CSSRCI
                Controller.CSROp        = rs1 != '0 ? HighLevelControl::Clear : HighLevelControl::Read;
                Controller.ImmSrcA      = HighLevelControl::CSRValType;
                Controller.AluSrcA      = HighLevelControl::Imm;
            end
            default: begin
                Controller.RegWrite     = 1'b0;
                Controller.CSREn        = 1'b0;
            end
        endcase

    end

endmodule

`endif
