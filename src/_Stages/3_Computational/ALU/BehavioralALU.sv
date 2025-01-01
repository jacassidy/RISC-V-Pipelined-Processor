//James Kaden Cassidy jkc.cassidy@gmail.com 12/20/2024

`include "parameters.svh"

import HighLevelControl::*;

module behavioralAlu #(

) (
    input HighLevelControl::aluOperation    ALUOp,

    input logic[`BIT_COUNT - 1 : 0]          ALUOpA,
    input logic[`BIT_COUNT - 1 : 0]          ALUOpB,

    output logic                            Zero,
    output logic                            oVerflow,
    output logic                            Negative,
    output logic                            Carry,
    
    output logic[`BIT_COUNT - 1 : 0]         ALUResult
);

    assign Negative            = ALUResult[`BIT_COUNT-1];
    assign Zero                = ~(|ALUResult);

    always_comb begin
        casex(ALUOp)
            ADD: begin //ADD
                {Carry, ALUResult}  = ALUOpA + ALUOpB;
                oVerflow            = ~(ALUOpA[`BIT_COUNT-1] ^ ALUOpB[`BIT_COUNT-1]) 
                                        & (ALUOpA[`BIT_COUNT-1] ^ ALUResult[`BIT_COUNT-1]);
            end
            SUB: begin //SUB
                {Carry, ALUResult}  = ALUOpA - ALUOpB;
                oVerflow            = ~(ALUOpA[`BIT_COUNT-1] ^ ALUOpB[`BIT_COUNT-1] ^ 1'b1) 
                                        & (ALUOpA[`BIT_COUNT-1] ^ ALUResult[`BIT_COUNT-1]);
                
            end
            OR: begin //OR
                Carry       = 0;
                ALUResult   = ALUOpA | ALUOpB;
                oVerflow    = 0;
            end
            AND: begin //AND
                Carry       = 0;
                ALUResult   = ALUOpA & ALUOpB;
                oVerflow    = 0;
            end
            XOR: begin //XOR
                Carry       = 0;
                ALUResult   = ALUOpA ^ ALUOpB;
                oVerflow    = 0;
            end
            SLL: begin //SLL
                Carry       = 0;
                ALUResult   = ALUOpA << ALUOpB[($clog2(`BIT_COUNT)-1):0];
                oVerflow    = 0;
            end
            SRL: begin //SRL
                Carry       = 0;
                ALUResult   = ALUOpA >> ALUOpB[($clog2(`BIT_COUNT)-1):0];
                oVerflow    = 0;
            end
            SRA: begin //SRA
                Carry       = 0;
                ALUResult   = $signed(ALUOpA) >>> ALUOpB[($clog2(`BIT_COUNT)-1):0];
                oVerflow    = 0;
            end
            SLTU: begin //SLTU
                logic[`BIT_COUNT:0] Sub;
                Sub         = ALUOpA - ALUOpB;

                Carry       = Sub[`BIT_COUNT];
                ALUResult   = {{(`BIT_COUNT-1) {1'b0}} , Carry};
                oVerflow    = ~(ALUOpA[`BIT_COUNT-1] ^ ALUOpB[`BIT_COUNT-1] ^ 1'b1) 
                                    & (ALUOpA[`BIT_COUNT-1] ^ ALUResult[`BIT_COUNT-1]);
                
            end
            SLT: begin //SLT
                logic[`BIT_COUNT:0] Sub;
                Sub         = ALUOpA - ALUOpB;

                Carry       = Sub[`BIT_COUNT];
                //If result is negative (sign inverted by overflow)
                ALUResult   = {{(`BIT_COUNT-1) {1'b0}} , Sub[`BIT_COUNT-1] ^ oVerflow};
                oVerflow    = ~(ALUOpA[`BIT_COUNT-1] ^ ALUOpB[`BIT_COUNT-1] ^ 1'b1) 
                                    & (ALUOpA[`BIT_COUNT-1] ^ ALUResult[`BIT_COUNT-1]);
                
            end

            `ifdef BIT_COUNT_64

                //32 bit opperations in RV64I
                SLLW: begin //SLL
                    Carry       = 0;
                    ALUResult   = {(`WORD_SIZE'bx), ALUOpA[`WORD_SIZE-1:0] << ALUOpB[($clog2(`WORD_SIZE)-1):0]};
                    oVerflow    = 0;
                end
                SRLW: begin //SRL
                    Carry       = 0;
                    ALUResult   = {`WORD_SIZE'bx, ALUOpA[`WORD_SIZE-1:0] >> ALUOpB[($clog2(`WORD_SIZE)-1):0]};
                    oVerflow    = 0;
                end
                SRAW: begin //SRA
                    Carry       = 0;
                    ALUResult   = {`WORD_SIZE'bx, $signed(ALUOpA[`WORD_SIZE-1:0]) >>> ALUOpB[($clog2(`WORD_SIZE)-1):0]};
                    oVerflow    = 0;
                end
            `endif 

            default: begin
                ALUResult   = 'x;
                Carry       = 'x;
                oVerflow    = 'x;
            end
        endcase
    end
    
endmodule