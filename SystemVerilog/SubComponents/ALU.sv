module alu #(
    WIDTH = 32
) (
    input HighLevelControl::aluOperation ALUCtrl,
    input logic[WIDTH - 1 : 0] ALUOpA,
    input logic[WIDTH - 1 : 0] ALUOpB,

    output logic[WIDTH - 1 : 0] ALUResult,
);
    import HighLevelControl::*;
    casex(ALUCtrl)
        ADD: begin //ADD
            assign ALUResult = ALUOpA + ALUOpB;
        end
        SUB: begin //SUB
            assign ALUResult = ALUOpA - ALUOpB;
        end
        OR: begin //OR
            assign ALUResult = ALUOpA | ALUOpB;
        end
        AND: begin //AND
            assign ALUResult = ALUOpA & ALUOpB;
        end
        XOR: begin //XOR
            assign ALUResult = ALUOpA ^ ALUOpB;
        end
        3'bxxx: begin //SLL
            assign ALUResult = ALUOpA ^ ALUOpB;
        end
        3'bxxx: begin //SRL
            assign ALUResult = ALUOpA ^ ALUOpB;
        end
        3'bxxx: begin //SRA
            assign ALUResult = ALUOpA ^ ALUOpB;
        end
        3'bxxx: begin //SLTU
            assign ALUResult = ALUOpA ^ ALUOpB;
        end
        3'bxxx: begin //SLT
            assign ALUResult = ALUOpA ^ ALUOpB;
        end

        default: begin
            assign ALUResult = 'x;
        end
    endcase
    
endmodule