//James Kaden Cassidy jkc.cassidy@gmail.com 12/31/2025

`include "parameters.svh"

`ifdef ZICSR
module ZICSR_CSRs (
        input   logic                   clk,
        input   logic                   reset,

        output   ZICSRType::csrCtrl     ustatus_ctrl,
        output   ZICSRType::csrCtrl     mstatus_ctrl,
        output   ZICSRType::csrCtrl     mtvec_ctrl,
        output   ZICSRType::csrCtrl     mhartid_ctrl
    );

    assign ustatus_ctrl.Name            = ZICSRType::ustatus; // ustatus
    assign mstatus_ctrl.Name            = ZICSRType::mstatus; // mstatus
    assign mtvec_ctrl.Name              = ZICSRType::mtvec;   // mtvec
    assign mhartid_ctrl.Name            = ZICSRType::mhartid; // mhartid

    assign ustatus_ctrl.DefaultValue    = '0;               // ustatus
    assign mstatus_ctrl.DefaultValue    = `XLEN'h0000_1880; // mstatus
    assign mtvec_ctrl.DefaultValue      = `XLEN'h8000_0000;
    assign mhartid_ctrl.DefaultValue    = '0;               // mhartid

    assign ustatus_ctrl.WriteEn         = 1'b0;             // ustatus
    assign mstatus_ctrl.WriteEn         = 1'b1;             // mstatus
    assign mtvec_ctrl.WriteEn           = 1'b1;             // mtvec
    assign mhartid_ctrl.WriteEn         = 1'b0;             // mhartid

    assign ustatus_ctrl.ReadEn          = 1'b1;             // ustatus
    assign mstatus_ctrl.ReadEn          = 1'b1;             // mstatus
    assign mtvec_ctrl.ReadEn            = 1'b0;             // mtvec
    assign mhartid_ctrl.ReadEn          = 1'b1;             // mhartid

    assign ustatus_ctrl.InternalWriteEn = 1'b0;             // ustatus
    assign mstatus_ctrl.InternalWriteEn = 1'b0;             // mstatus
    assign mtvec_ctrl.InternalWriteEn   = 1'b0;             // mtvec
    assign mhartid_ctrl.InternalWriteEn = 1'b0;             // mhartid

    assign ustatus_ctrl.InternalWriteData = 'x;             // ustatus
    assign mstatus_ctrl.InternalWriteData = 'x;             // mstatus
    assign mtvec_ctrl.InternalWriteData   = 'x;             // mtvec
    assign mhartid_ctrl.InternalWriteData = 'x;             // mhartid

endmodule
`endif
