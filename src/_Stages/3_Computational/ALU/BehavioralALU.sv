//James Kaden Cassidy jkc.cassidy@gmail.com 12/20/2024

`include "parameters.svh"

import HighLevelControl::*;

module behavioralAlu #(

) (
    input HighLevelControl::aluOperation    AluOperation,

    input logic[`XLEN-1:0]             AluOperandA,
    input logic[`XLEN-1:0]             AluOperandB,

    output logic                            Zero,
    output logic                            oVerflow,
    output logic                            Negative,
    output logic                            Carry,

    output logic[`XLEN-1:0]            AluResult
);

    assign Negative                 = AluResult[`XLEN-1];
    assign Zero                     = ~(|AluResult);

    always_comb begin
        casex(AluOperation)
            ADD: begin //ADD
                {Carry, AluResult}  = AluOperandA + AluOperandB;
                oVerflow            = ~(AluOperandA[`XLEN-1] ^ AluOperandB[`XLEN-1])
                                        & (AluOperandA[`XLEN-1] ^ AluResult[`XLEN-1]);
            end
            SUB: begin //SUB
                {Carry, AluResult}  = AluOperandA - AluOperandB;
                oVerflow            = ~(AluOperandA[`XLEN-1] ^ AluOperandB[`XLEN-1] ^ 1'b1)
                                        & (AluOperandA[`XLEN-1] ^ AluResult[`XLEN-1]);

            end
            OR: begin //OR
                Carry               = 0;
                AluResult           = AluOperandA | AluOperandB;
                oVerflow            = 0;
            end
            AND: begin //AND
                Carry               = 0;
                AluResult           = AluOperandA & AluOperandB;
                oVerflow            = 0;
            end
            XOR: begin //XOR
                Carry               = 0;
                AluResult           = AluOperandA ^ AluOperandB;
                oVerflow            = 0;
            end
            SLL: begin //SLL
                Carry               = 0;
                AluResult           = AluOperandA << AluOperandB[($clog2(`XLEN)-1):0];
                oVerflow            = 0;
            end
            SRL: begin //SRL
                Carry               = 0;
                AluResult           = AluOperandA >> AluOperandB[($clog2(`XLEN)-1):0];
                oVerflow            = 0;
            end
            SRA: begin //SRA
                Carry               = 0;
                AluResult           = $signed(AluOperandA) >>> AluOperandB[($clog2(`XLEN)-1):0];
                oVerflow            = 0;
            end
            SLTU: begin //SLTU
                logic[`XLEN:0] Sub;
                Sub                 = AluOperandA - AluOperandB;

                Carry               = Sub[`XLEN];
                AluResult           = {{(`XLEN-1) {1'b0}} , Carry};
                oVerflow            = ~(AluOperandA[`XLEN-1] ^ AluOperandB[`XLEN-1] ^ 1'b1)
                                        & (AluOperandA[`XLEN-1] ^ Sub[`XLEN-1]);

            end
            SLT: begin //SLT
                logic[`XLEN:0] Sub;
                Sub                 = AluOperandA - AluOperandB;

                Carry               = Sub[`XLEN];
                oVerflow            = ~(AluOperandA[`XLEN-1] ^ AluOperandB[`XLEN-1] ^ 1'b1)
                                        & (AluOperandA[`XLEN-1] ^ Sub[`XLEN-1]);
                //If result is negative (sign inverted by overflow)
                AluResult           = {{(`XLEN-1) {1'b0}}, Sub[`XLEN-1] ^ oVerflow};


            end

            `ifdef XLEN_64

                //Needed for Hazzard forwarding in RV64I
                ADDW: begin
                    logic[`WORD_SIZE-1:0] Alu32BitResult;
                    {Carry, Alu32BitResult} = AluOperandA[`WORD_SIZE-1:0] + AluOperandB[`WORD_SIZE-1:0];
                    AluResult               = {{(`WORD_SIZE) {Alu32BitResult[`WORD_SIZE-1]}}, Alu32BitResult};
                    oVerflow                = ~(AluOperandA[`WORD_SIZE-1] ^ AluOperandB[`WORD_SIZE-1])
                                            & (AluOperandA[`WORD_SIZE-1] ^ Alu32BitResult[`WORD_SIZE-1]);
                end
                SUBW: begin
                    logic[`WORD_SIZE-1:0] Alu32BitResult;
                    {Carry, Alu32BitResult} = AluOperandA[`WORD_SIZE-1:0] - AluOperandB[`WORD_SIZE-1:0];
                    AluResult               = {{(`WORD_SIZE) {Alu32BitResult[`WORD_SIZE-1]}}, Alu32BitResult};
                    oVerflow                = ~(AluOperandA[`WORD_SIZE-1] ^ AluOperandB[`WORD_SIZE-1] ^ 1'b1)
                                            & (AluOperandA[`WORD_SIZE-1] ^ Alu32BitResult[`WORD_SIZE-1]);
                end

                //32 bit opperations in RV64I
                SLLW: begin //SLL
                    logic[`WORD_SIZE-1:0] Alu32BitResult;
                    Carry           = 0;
                    Alu32BitResult  = AluOperandA[`WORD_SIZE-1:0] << AluOperandB[($clog2(`WORD_SIZE)-1):0];
                    AluResult       = {{(`WORD_SIZE) {Alu32BitResult[`WORD_SIZE-1]}}, Alu32BitResult};
                    oVerflow        = 0;
                end
                SRLW: begin //SRL
                    logic[`WORD_SIZE-1:0] Alu32BitResult;
                    Carry           = 0;
                    Alu32BitResult  = {AluOperandA[`WORD_SIZE-1:0] >> AluOperandB[($clog2(`WORD_SIZE)-1):0]};
                    AluResult       = {{(`WORD_SIZE) {Alu32BitResult[`WORD_SIZE-1]}}, Alu32BitResult};
                    oVerflow        = 0;
                end
                SRAW: begin //SRA
                    logic[`WORD_SIZE-1:0] Alu32BitResult;
                    Carry           = 0;
                    Alu32BitResult  = $signed(AluOperandA[`WORD_SIZE-1:0]) >>> AluOperandB[($clog2(`WORD_SIZE)-1):0];
                    AluResult       = {{(`WORD_SIZE) {Alu32BitResult[`WORD_SIZE-1]}}, Alu32BitResult};
                    oVerflow        = 0;
                end
            `endif

            default: begin
                AluResult           = 'x;
                Carry               = 'x;
                oVerflow            = 'x;
            end
        endcase
    end

endmodule
