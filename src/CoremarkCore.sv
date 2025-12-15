//James Kaden Cassidy jkc.cassidy@gmail.com 12/20/2024

`include "parameters.svh"

module CoremarkCore(
    input   logic                       clk,
    input   logic                       reset,

    output  logic [`XLEN-1:0]           imem_addr,  // instruction memory target address
    input   logic [`XLEN-1:0]           imem_rdata, // instruction memory read data

    output  logic [`XLEN-1:0]           dmem_addr,  // data memory target address
    input   logic [`XLEN-1:0]           dmem_rdata, // data memory read data
    output  logic [`XLEN-1:0]           dmem_wdata, // data memory write data

    output  logic                       dmem_rvalid,
    output  logic [$clog2(`XLEN)-1:0]   dmem_wstrb  // strobes, 1 hot stating weather a byte should be written on a store
  );

    logic[`BIT_COUNT-1:0]       InstrAdr;
    logic[31:0]                 Instr;

    logic                       MemEn, MemWriteEn;
    logic[`BIT_COUNT-1:0]       MemWriteData, MemReadData;
    logic[`BIT_COUNT-1:0]       MemAdr;
    logic[(`BIT_COUNT/8)-1:0]   MemByteEn;

    //Instruction Memory
    assign imem_addr = InstrAdr;
    assign Instr     = imem_rdata;

    //Compute Core
    computeCore ComputeCore(.clk, .reset, .External_PC(InstrAdr), .External_MemEn(MemEn), .External_MemWriteEn(MemWriteEn), 
        .External_MemByteEn(MemByteEn), .External_MemAdr(MemAdr), .External_MemWriteData(MemWriteData), 
        .External_Instr(Instr), .External_MemReadData(MemReadData));

    //Data Memory
    assign dmem_wstrb   = MemByteEn & {4{MemWriteEn}};
    assign dmem_addr    = MemAdr;
    assign dmem_wdata   = MemWriteData;
    assign dmem_rvalid  = MemEn;

    assign MemReadData  = dmem_rdata;

endmodule
