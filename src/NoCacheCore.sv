//James Kaden Cassidy jkc.cassidy@gmail.com 12/20/2024

`define WORD_SIZE 32

module noCacheCore #(
    parameter INSTRUCTION_MEMORY_FILE_NAME,
    parameter BIT_COUNT
) (
    input logic clk,
    input logic reset
);

    //Instruction Memory
    logic[BIT_COUNT-1:0] InstrAdr;
    logic[31:0] Instr;

    vectorStorage #(.MEMORY_FILE_PATH(""), .MEMORY_SIZE_BITS(32 * 100), .ADRESS_SIZE(BIT_COUNT)) 
        InstructionMemory(.MemEn(1), .WriteEnable(0), 
        .ByteEn(0), .MemoryAdress(InstrAdr), .InputData(0), .MemData(Instr));
    
    //Data Memory
    logic MemEn, MemWrite;
    logic[31:0] MemWriteData, MemReadData;
    logic[BIT_COUNT-1:0] MemAdr;
    logic[(`WORD_SIZE/8)-1:0] ByteEn;

    vectorStorage #(.MEMORY_FILE_PATH(""), .MEMORY_SIZE_BITS(32 * 100), .ADRESS_SIZE(BIT_COUNT)) 
        DataMemory(.MemEn, .WriteEnable(MemWrite), 
        .ByteEn, .MemoryAdress(MemAdr), .InputData(MemWriteData), .MemData(MemReadData));

    //Compute Core
    computeCore #(.BIT_COUNT(BIT_COUNT)) ComputeCore(.clk, .reset, .PC(InstrAdr), .MemEn, .MemWrite, 
        .ByteEn, .MemAdr, .MemWriteData, .Instr, .MemReadData);
    
endmodule