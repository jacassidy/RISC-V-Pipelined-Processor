module controller #(
    WORD_SIZE
) (
    input logic[6:0] opcode,
    input logic[2:0] funct3,
    input logic[6:0] funct7,

    output logic PCUpdate,
    output logic RegWrite,
    output HighLevelControl::immExtender ImmSrc,
    output logic ALUSrcA,
    output logic ALUSrcB,
    output HighLevelControl::aluOperation ALUCtrl,
    output logic MemWrite,
);

    logic [4:0] ControllerSignals, RTypeSignals;
    assign {PCUpdate, RegWrite, ALUSrcA, ALUSrcB, MemWrite} = ControllerSignals;

    HighLevelControl::aluOperation RTypeALUTCtrl;

    //R-Type Controller
    rTypeController RTypeController(.funct7, .funct3, .ALUCtrl(RTypeALUTCtrl), .signals(RTypeSignals));

    always_comb begin
        casex(opcode)
            7'b0110011: begin //R Type
                assign ControllerSignals = RTypeSignals;
                assign ALUCtrl = RTypeALUTCtrl;
            end

            default: begin
                assign ControllerSignals = 'x;
                assign ALUCtrl = NONE;
                assign ImmSrc = NONE;
            end
        endcase

    end
    
endmodule

module rTypeController(
    input logic[6:0] funct7,
    input logic[2:0] funct3,

    output HighLevelControl::aluOperation ALUCtrl,
    output HighLevelControl::immExtender ImmSrc;
    output logic[4:0] singals
);
    import HighLevelControl::*;

    assign signals = 5'b0_1_0_0_0;
    assign ImmSrc = 'x;
    
    always_comb begin
        casex({funct7, funct3})
            10'b0000000_000: assign ALUCtrl = ADD;
            10'b0100000_000: assign ALUCtrl = SUB;
            10'b0000000_110: assign ALUCtrl = OR;
            10'b0000000_111: assign ALUCtrl = AND;
            10'b0000000_100: assign ALUCtrl = XOR;
            10'b0000000_001: assign ALUCtrl = SLL;
            10'b0000000_010: assign ALUCtrl = SLT;
            10'b0000000_011: assign ALUCtrl = SLTU;
            10'b0000000_101: assign ALUCtrl = SRL;
            10'b0100000_101: assign ALUCtrl = SRA;
            
            default: assign ALUCtrl = NONE;
            
        endcase
    end

endmodule