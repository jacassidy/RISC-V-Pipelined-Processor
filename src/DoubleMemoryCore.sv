//James Kaden Cassidy jkc.cassidy@gmail.com 12/20/2024

`define WORD_SIZE 32

module doubleMemoryCore #(
    parameter INSTRUCTION_MEMORY_FILE_NAME,
    parameter BIT_COUNT
) (
    input logic clk,
    input logic reset
);

    logic[BIT_COUNT-1:0] InstrAdr;
    logic[31:0] Instr;

    logic MemEn, MemWrite;
    logic[31:0] MemWriteData, MemReadData;
    logic[BIT_COUNT-1:0] MemAdr;
    logic[(`WORD_SIZE/8)-1:0] ByteEn;

    //Instruction Memory
    vectorStorage #(.MEMORY_FILE_PATH(INSTRUCTION_MEMORY_FILE_NAME), .MEMORY_SIZE_WORDS(64), .ADRESS_SIZE(BIT_COUNT)) 
        InstructionMemory(.clk, .reset(1'b0), .MemEn(1'b1), .WriteEnable(1'b0), 
        .ByteEn(4'b0), .MemoryAdress(InstrAdr), .InputData(`WORD_SIZE'b0), .MemData(Instr));

    //Compute Core
    computeCore #(.BIT_COUNT(BIT_COUNT)) ComputeCore(.clk, .reset, .PC(InstrAdr), .MemEn, .MemWrite, 
        .ByteEn, .MemAdr, .MemWriteData, .Instr, .MemReadData);

    //Data Memory
    vectorStorage #(.MEMORY_FILE_PATH(""), .MEMORY_SIZE_WORDS(64), .ADRESS_SIZE(BIT_COUNT)) 
        DataMemory(.clk, .reset, .MemEn, .WriteEnable(MemWrite), 
        .ByteEn, .MemoryAdress(MemAdr), .InputData(MemWriteData), .MemData(MemReadData));

    
    
endmodule