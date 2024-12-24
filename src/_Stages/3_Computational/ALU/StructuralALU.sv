//James Kaden Cassidy jkc.cassidy@gmail.com 12/23/2024

module stucturalAlu #(
    BIT_COUNT = 32
) (
    input logic Invert,
    input logic[BIT_COUNT - 1 : 0] ALUOpA,
    input logic[BIT_COUNT - 1 : 0] ALUOpB,

    output logic[BIT_COUNT - 1 : 0] Add,
    output logic[BIT_COUNT - 1 : 0] Or,
    output logic[BIT_COUNT - 1 : 0] And,
    output logic[BIT_COUNT - 1 : 0] Xor,
);

    
endmodule