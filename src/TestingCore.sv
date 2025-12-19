//James Kaden Cassidy jkc.cassidy@gmail.com 12/20/2024

`include "parameters.svh"

module testingCore(
    input   logic                       clk,
    input   logic                       reset,

    output  logic [`XLEN-1:0]           PC,  // instruction memory target address
    input   logic [`XLEN-1:0]           Instr, // instruction memory read data

    output  logic [`XLEN-1:0]           IEUAdr,  // data memory target address
    input   logic [`XLEN-1:0]           ReadData, // data memory read data
    output  logic [`XLEN-1:0]           WriteData, // data memory write data

    output  logic                       MemEn,
    output  logic                       WriteEn,
    output  logic [`XLEN/8-1:0]         WriteByteEn  // strobes, 1 hot stating weather a byte should be written on a store
  );

    logic[`BIT_COUNT-1:0]       InstrAdr;

    logic                       MemWriteEn;
    logic[`BIT_COUNT-1:0]       MemWriteData, MemReadData;
    logic[`BIT_COUNT-1:0]       MemAdr;
    logic[(`BIT_COUNT/8)-1:0]   MemByteEn;

    //Instruction Memory
    assign PC = InstrAdr;

    //Compute Core
    computeCore ComputeCore(.clk, .reset, .External_PC(InstrAdr), .External_MemEn(MemEn), .External_MemWriteEn(MemWriteEn),
        .External_MemByteEn(MemByteEn), .External_MemAdr(MemAdr), .External_MemWriteData(MemWriteData),
        .External_Instr(Instr), .External_MemReadData(MemReadData));

    //Data Memory
    assign WriteByteEn      = MemByteEn & {4{MemWriteEn}};
    assign IEUAdr           = MemAdr;
    assign WriteData        = MemWriteData;
    assign WriteEn          = MemWriteEn;

    assign MemReadData  = ReadData;

endmodule
