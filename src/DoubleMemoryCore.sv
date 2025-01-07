//James Kaden Cassidy jkc.cassidy@gmail.com 12/20/2024

`include "parameters.svh"

module doubleMemoryCore #(
    parameter INSTRUCTION_MEMORY_FILE_NAME
) (
    input logic clk,
    input logic reset
);

    logic[`BIT_COUNT-1:0]       InstrAdr;
    logic[31:0]                 Instr;

    logic                       MemEn, MemWriteEn;
    logic[`BIT_COUNT-1:0]       MemWriteData, MemReadData;
    logic[`BIT_COUNT-1:0]       MemAdr;
    logic[(`BIT_COUNT/8)-1:0]   MemByteEn;

    //Instruction Memory
    vectorStorage #(.MEMORY_FILE_PATH(INSTRUCTION_MEMORY_FILE_NAME), .MEMORY_SIZE_WORDS(128), .ADRESS_SIZE(`BIT_COUNT), .BIT_COUNT(32)) 
        InstructionMemory(.clk, .reset(1'b0), .En(1'b1), .WriteEn(1'b0), 
        .ByteEn(4'b0), .MemoryAdress(InstrAdr), .InputData(`WORD_SIZE'b0), .MemData(Instr));

    //Compute Core
    computeCore ComputeCore(.clk, .reset, .External_PC(InstrAdr), .External_MemEn(MemEn), .External_MemWriteEn(MemWriteEn), 
        .External_MemByteEn(MemByteEn), .External_MemAdr(MemAdr), .External_MemWriteData(MemWriteData), 
        .External_Instr(Instr), .External_MemReadData(MemReadData));

    //Data Memory
    vectorStorage #(.MEMORY_FILE_PATH(""), .MEMORY_SIZE_WORDS(64), .ADRESS_SIZE(`BIT_COUNT), .BIT_COUNT(`BIT_COUNT)) 
        DataMemory(.clk, .reset, .En(MemEn), .WriteEn(MemWriteEn), 
        .ByteEn(MemByteEn), .MemoryAdress(MemAdr), .InputData(MemWriteData), .MemData(MemReadData));

    
    
endmodule