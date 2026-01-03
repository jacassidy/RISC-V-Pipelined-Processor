// //James Kaden Cassidy jkc.cassidy@gmail.com 12/20/2024

// `include "parameters.svh"

// module doubleMemoryCore #(
//     parameter INSTRUCTION_MEMORY_FILE_NAME
// ) (
//     input logic clk,
//     input logic reset
// );

//     logic[`XLEN-1:0]       InstrAdr;
//     logic[31:0]                 Instr;

//     logic                       MemEn, MemWriteEn;
//     logic[`XLEN-1:0]       MemWriteData, MemReadData;
//     logic[`XLEN-1:0]       MemAdr;
//     logic[(`XLEN/8)-1:0]   MemWriteByteEn;

//     //Instruction Memory
//     vectorStorage #(.MEMORY_FILE_PATH(INSTRUCTION_MEMORY_FILE_NAME), .MEMORY_SIZE_WORDS(128), .ADDRESS_SIZE(`XLEN), .XLEN(32))
//         InstructionMemory(.clk, .reset(1'b0), .En(1'b1), .WriteEn(1'b0),
//         .ByteEn(4'b0), .MemoryAddress(InstrAdr), .InputData(`WORD_SIZE'b0), .MemData(Instr));

//     //Compute Core
//     computeCore ComputeCore(.clk, .reset, .External_PC(InstrAdr), .External_MemEn(MemEn), .External_MemWriteEn(MemWriteEn),
//         .External_MemWriteByteEn(MemWriteByteEn), .External_MemAdr(MemAdr), .External_MemWriteData(MemWriteData),
//         .External_Instr(Instr), .External_MemReadData(MemReadData));

//     //Data Memory
//     vectorStorage #(.MEMORY_FILE_PATH(""), .MEMORY_SIZE_WORDS(64), .ADDRESS_SIZE(`XLEN), .XLEN(`XLEN))
//         DataMemory(.clk, .reset, .En(MemEn), .WriteEn(MemWriteEn),
//         .ByteEn(MemWriteByteEn), .MemoryAddress(MemAdr), .InputData(MemWriteData), .MemData(MemReadData));



// endmodule
