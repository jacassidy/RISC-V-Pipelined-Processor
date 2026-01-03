//James Kaden Cassidy jkc.cassidy@gmail.com 12/27/2025

`include "parameters.svh"

`ifdef ZICNTR
module ZICNTR_CSRs (
        input   logic                   clk,
        input   logic                   reset,

        input   logic                   InstructionRetired,

        input   logic[63:0]             CycleCSRValue,
        input   logic[63:0]             InsretCSRValue,

        output   ZICSRType::csrCtrl           rdcycle_ctrl,
        output   ZICSRType::csrCtrl           rdtime_ctrl,
        output   ZICSRType::csrCtrl           rdinsret_ctrl,
        output   ZICSRType::csrCtrl           minsret_ctrl
        `ifdef XLEN_32
        , output   ZICSRType::csrCtrl         rdcycleh_ctrl
        , output   ZICSRType::csrCtrl         rdtimeh_ctrl
        , output   ZICSRType::csrCtrl         rdinsreth_ctrl
        `endif
    );

    logic[63:0] CycleCSRValueNext;
    logic[63:0] TimeCSRValueNext;
    logic[63:0] InsretCSRValueNext;

    // Determine values
    assign CycleCSRValueNext                = CycleCSRValue + 1;
    assign TimeCSRValueNext                 = CycleCSRValueNext;
    assign InsretCSRValueNext               = InsretCSRValue + 64'(InstructionRetired);

    // Assign back next values
    assign rdcycle_ctrl.InternalWriteData   = CycleCSRValueNext [`XLEN-1:0];
    assign rdtime_ctrl.InternalWriteData    = TimeCSRValueNext  [`XLEN-1:0];
    assign rdinsret_ctrl.InternalWriteData  = InsretCSRValueNext[`XLEN-1:0];

    `ifdef XLEN_32
    assign rdcycleh_ctrl.InternalWriteData  = CycleCSRValueNext [63:32];
    assign rdtimeh_ctrl.InternalWriteData   = TimeCSRValueNext  [63:32];
    assign rdinsreth_ctrl.InternalWriteData = InsretCSRValueNext[63:32];
    `endif

    // Assign names
    assign rdcycle_ctrl.Name                = ZICSRType::rdcycle;
    assign rdtime_ctrl.Name                 = ZICSRType::rdtime;
    assign rdinsret_ctrl.Name               = ZICSRType::rdinsret;
    `ifdef XLEN_32
    assign rdcycleh_ctrl.Name               = ZICSRType::rdcycleh;
    assign rdtimeh_ctrl.Name                = ZICSRType::rdtimeh;
    assign rdinsreth_ctrl.Name              = ZICSRType::rdinsreth;
    `endif

    // Assign defaults
    assign rdcycle_ctrl.DefaultValue        = '0;
    assign rdtime_ctrl.DefaultValue         = '0;
    assign rdinsret_ctrl.DefaultValue       = '0;
    `ifdef XLEN_32
    assign rdcycleh_ctrl.DefaultValue       = '0;
    assign rdtimeh_ctrl.DefaultValue        = '0;
    assign rdinsreth_ctrl.DefaultValue      = '0;
    `endif

    // Set Read write permissions
    assign rdcycle_ctrl.WriteEn             = 1'b0;
    assign rdtime_ctrl.WriteEn              = 1'b0;
    assign rdinsret_ctrl.WriteEn            = 1'b0;

    assign rdcycle_ctrl.ReadEn              = 1'b1;
    assign rdtime_ctrl.ReadEn               = 1'b1;
    assign rdinsret_ctrl.ReadEn             = 1'b1;

    assign rdcycle_ctrl.InternalWriteEn     = 1'b1;
    assign rdtime_ctrl.InternalWriteEn      = 1'b1;
    assign rdinsret_ctrl.InternalWriteEn    = 1'b1;

    `ifdef XLEN_32
    assign rdcycleh_ctrl.WriteEn            = 1'b0;
    assign rdtimeh_ctrl.WriteEn             = 1'b0;
    assign rdinsreth_ctrl.WriteEn           = 1'b0;

    assign rdcycleh_ctrl.ReadEn             = 1'b1;
    assign rdtimeh_ctrl.ReadEn              = 1'b1;
    assign rdinsreth_ctrl.ReadEn            = 1'b1;

    assign rdcycleh_ctrl.InternalWriteEn    = 1'b1;
    assign rdtimeh_ctrl.InternalWriteEn     = 1'b1;
    assign rdinsreth_ctrl.InternalWriteEn   = 1'b1;
    `endif

    assign minsret_ctrl.Name                     = ZICSRType::minsret;
    assign minsret_ctrl.DefaultValue             = '0;               // minsret
    assign minsret_ctrl.WriteEn                  = 1'b0;             // minsret
    assign minsret_ctrl.ReadEn                   = 1'b1;             // minsret
    assign minsret_ctrl.InternalWriteEn          = 1'b1;             // minsret
    assign minsret_ctrl.InternalWriteData        = InsretCSRValueNext[`XLEN-1:0]; // minsret = insret

endmodule
`endif
