//James Kaden Cassidy jkc.cassidy@gmail.com 12/20/2024

module alu #(
    BIT_COUNT = 32
) (
    input HighLevelControl::aluOperation ALUOp,
    input logic[BIT_COUNT - 1 : 0] ALUOpA,
    input logic[BIT_COUNT - 1 : 0] ALUOpB,

    output logic[BIT_COUNT - 1 : 0] ALUResult,
);
    import HighLevelControl::aluOperation::*;
    casex(ALUOp)
        ADD: begin //ADD
            ALUResult = ALUOpA + ALUOpB;
        end
        SUB: begin //SUB
            ALUResult = ALUOpA - ALUOpB;
        end
        OR: begin //OR
            ALUResult = ALUOpA | ALUOpB;
        end
        AND: begin //AND
            ALUResult = ALUOpA & ALUOpB;
        end
        XOR: begin //XOR
            ALUResult = ALUOpA ^ ALUOpB;
        end
        SLL: begin //SLL
            ALUResult = ALUOpA << ALUOpB[4:0];
        end
        SRL: begin //SRL
            ALUResult = ALUOpA >> ALUOpB[4:0];
        end
        SRA: begin //SRA
            ALUResult = $signed(ALUOpA) >>> ALUOpB[4:0];
        end
        SLTU: begin //SLTU
            ALUResult = {(BIT_COUNT-1) * 1'b0 ,(ALUOpA < ALUOpB) ? 1'd1 : 1'd0};
        end
        SLT: begin //SLT
            ALUResult = {(BIT_COUNT-1) * 1'b0 ,($signed(ALUOpA) < $signed(ALUOpB)) ? 1'd1 : 1'd0};
        end

        default: begin
            ALUResult = 'x;
        end
    endcase
    
endmodule