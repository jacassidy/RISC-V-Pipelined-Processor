//James Kaden Cassidy jkc.cassidy@gmail.com 1/2/2026

`include "parameters.svh"

module _IStage (
    input  logic                    clk,
    input  logic                    reset,

    input  logic [`XLEN-1:0]        PCNext_I,

`ifdef PIPELINED
    input  logic                    StallPC,
`endif

    // External instruction fetch
    output logic [`XLEN-1:0]        External_PC,
    input  logic [`WORD_SIZE-1:0]   External_Instr,

    // To IR pipeline regs (in computeCore)
    output logic [`XLEN-1:0]        PC_I,
    output logic [`XLEN-1:0]        PCp4_I,
    output logic [`WORD_SIZE-1:0]   Instr_I,
    output logic                    ValidInstruction_I
);

    logic [`XLEN-1:0] PROGRAM_ENTRY_ADR;
    initial begin
        PROGRAM_ENTRY_ADR = '0; // default
        void'($value$plusargs("ENTRY_ADDR=%h", PROGRAM_ENTRY_ADR)); // override if provided
        $display("[TB] ENTRY_ADDR = 0x%h", PROGRAM_ENTRY_ADR);
    end

    //Program Counter
    `ifdef PIPELINED
        always_ff @( posedge clk ) begin
            if (reset)          PC_I <= PROGRAM_ENTRY_ADR;
            else if (~StallPC)  PC_I <= PCNext_I;
        end
    `else
        always_ff @( posedge clk ) begin
            if (reset)  PC_I <= PROGRAM_ENTRY_ADR;
            else        PC_I <= PCNext_I;
        end
    `endif

    assign PCp4_I               = PC_I + 4;
    assign ValidInstruction_I   = 1'b1;

    //****Instruction cache controlled externally****//
    assign External_PC          = PC_I;
    assign Instr_I              = External_Instr;

endmodule
