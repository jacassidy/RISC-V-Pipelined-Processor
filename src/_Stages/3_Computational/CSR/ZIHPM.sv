// //James Kaden Cassidy jkc.cassidy@gmail.com 12/27/2025

// `include "parameters.svh"

// // Zihpm: Hardware Performance Monitoring
// // - Provides mhpmcounter3-31 (+ high halves on RV32), mhpmevent3-31, and mcountinhibit.
// // - This implementation FIXES the event mapping for the subset you asked for (CoreMark counters[] mapping)
// //   and leaves all other counters/events as read-only zeros (placeholders).

// `ifdef ZIHPM
// module ZIHPM_CSRs (
//         input   logic                   clk,
//         input   logic                   reset,

//         // Current CSR values (assembled 64b counters)
//         // Only the implemented counters need to be plumbed in.
//         input   logic [63:0]            MHPMCounter3Value,
//         input   logic [63:0]            MHPMCounter4Value,
//         input   logic [63:0]            MHPMCounter5Value,
//         input   logic [63:0]            MHPMCounter7Value,
//         input   logic [63:0]            MHPMCounter8Value,
//         input   logic [63:0]            MHPMCounter9Value,
//         input   logic [63:0]            MHPMCounter10Value,
//         input   logic [63:0]            MHPMCounter11Value,
//         input   logic [63:0]            MHPMCounter12Value,
//         input   logic [63:0]            MHPMCounter13Value,
//         input   logic [63:0]            MHPMCounter14Value,
//         input   logic [63:0]            MHPMCounter16Value,
//         input   logic [63:0]            MHPMCounter17Value,

//         // mcountinhibit CSR current value (bit N inhibits HPMN; bit0=CY, bit2=IR, etc.)
//         input   logic [`XLEN-1:0]       MCountInhibitValue,

//         // Event pulses (1 = increment by 1 for that cycle / event)
//         input   logic                   BranchRetired,               // counters[3]
//         input   logic                   JumpJRRetired,               // counters[4]
//         input   logic                   ReturnRetired,               // counters[5]
//         input   logic                   BranchMispredict,            // counters[7]
//         input   logic                   BTBMiss,                     // counters[8]
//         input   logic                   RASWrong,                    // counters[9]
//         input   logic                   BPClassWrong,                // counters[10]
//         input   logic                   LoadStall,                   // counters[11]
//         input   logic                   StoreStall,                  // counters[12]
//         input   logic                   DCacheAccess,                // counters[13]
//         input   logic                   DCacheMiss,                  // counters[14]
//         input   logic                   ICacheAccess,                // counters[16]
//         input   logic                   ICacheMiss,                  // counters[17]

//         // Control structs
//         output  ZICSRType::csrCtrl       mcountinhibit_ctrl,

//         output  ZICSRType::csrCtrl       mhpmevent3_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent4_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent5_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent6_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent7_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent8_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent9_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent10_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent11_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent12_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent13_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent14_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent15_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent16_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent17_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent18_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent19_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent20_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent21_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent22_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent23_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent24_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent25_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent26_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent27_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent28_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent29_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent30_ctrl,
//         output  ZICSRType::csrCtrl       mhpmevent31_ctrl,

//         output  ZICSRType::csrCtrl       mhpmcounter3_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter4_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter5_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter6_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter7_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter8_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter9_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter10_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter11_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter12_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter13_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter14_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter15_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter16_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter17_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter18_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter19_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter20_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter21_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter22_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter23_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter24_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter25_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter26_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter27_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter28_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter29_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter30_ctrl,
//         output  ZICSRType::csrCtrl       mhpmcounter31_ctrl

//         `ifdef XLEN_32
//         , output ZICSRType::csrCtrl       mhpmcounter3h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter4h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter5h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter6h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter7h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter8h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter9h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter10h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter11h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter12h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter13h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter14h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter15h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter16h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter17h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter18h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter19h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter20h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter21h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter22h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter23h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter24h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter25h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter26h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter27h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter28h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter29h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter30h_ctrl
//         , output ZICSRType::csrCtrl       mhpmcounter31h_ctrl
//         `endif
//     );

//     // ------------------------------------------------------------
//     // Inhibit gating (mcountinhibit bit N inhibits HPMN)
//     // ------------------------------------------------------------
//     logic hpm3_en,  hpm4_en,  hpm5_en,  hpm6_en,  hpm7_en,  hpm8_en,  hpm9_en;
//     logic hpm10_en, hpm11_en, hpm12_en, hpm13_en, hpm14_en, hpm15_en, hpm16_en, hpm17_en;

//     assign hpm3_en  = ~MCountInhibitValue[3];
//     assign hpm4_en  = ~MCountInhibitValue[4];
//     assign hpm5_en  = ~MCountInhibitValue[5];
//     assign hpm6_en  = ~MCountInhibitValue[6];
//     assign hpm7_en  = ~MCountInhibitValue[7];
//     assign hpm8_en  = ~MCountInhibitValue[8];
//     assign hpm9_en  = ~MCountInhibitValue[9];
//     assign hpm10_en = ~MCountInhibitValue[10];
//     assign hpm11_en = ~MCountInhibitValue[11];
//     assign hpm12_en = ~MCountInhibitValue[12];
//     assign hpm13_en = ~MCountInhibitValue[13];
//     assign hpm14_en = ~MCountInhibitValue[14];
//     assign hpm15_en = ~MCountInhibitValue[15];
//     assign hpm16_en = ~MCountInhibitValue[16];
//     assign hpm17_en = ~MCountInhibitValue[17];

//     // ------------------------------------------------------------
//     // Next values (64b) for implemented counters
//     // ------------------------------------------------------------
//     logic [63:0] MHPMCounter3Next;
//     logic [63:0] MHPMCounter4Next;
//     logic [63:0] MHPMCounter5Next;
//     logic [63:0] MHPMCounter7Next;
//     logic [63:0] MHPMCounter8Next;
//     logic [63:0] MHPMCounter9Next;
//     logic [63:0] MHPMCounter10Next;
//     logic [63:0] MHPMCounter11Next;
//     logic [63:0] MHPMCounter12Next;
//     logic [63:0] MHPMCounter13Next;
//     logic [63:0] MHPMCounter14Next;
//     logic [63:0] MHPMCounter16Next;
//     logic [63:0] MHPMCounter17Next;

//     // Fixed mapping (matches your CoreMark counters[] usage)
//     assign MHPMCounter3Next  = MHPMCounter3Value  + (hpm3_en  & BranchRetired);
//     assign MHPMCounter4Next  = MHPMCounter4Value  + (hpm4_en  & JumpJRRetired);
//     assign MHPMCounter5Next  = MHPMCounter5Value  + (hpm5_en  & ReturnRetired);
//     assign MHPMCounter7Next  = MHPMCounter7Value  + (hpm7_en  & BranchMispredict);
//     assign MHPMCounter8Next  = MHPMCounter8Value  + (hpm8_en  & BTBMiss);
//     assign MHPMCounter9Next  = MHPMCounter9Value  + (hpm9_en  & RASWrong);
//     assign MHPMCounter10Next = MHPMCounter10Value + (hpm10_en & BPClassWrong);
//     assign MHPMCounter11Next = MHPMCounter11Value + (hpm11_en & LoadStall);
//     assign MHPMCounter12Next = MHPMCounter12Value + (hpm12_en & StoreStall);
//     assign MHPMCounter13Next = MHPMCounter13Value + (hpm13_en & DCacheAccess);
//     assign MHPMCounter14Next = MHPMCounter14Value + (hpm14_en & DCacheMiss);
//     assign MHPMCounter16Next = MHPMCounter16Value + (hpm16_en & ICacheAccess);
//     assign MHPMCounter17Next = MHPMCounter17Value + (hpm17_en & ICacheMiss);

//     // ------------------------------------------------------------
//     // mcountinhibit control (RW; no internal updates)
//     // ------------------------------------------------------------
//     assign mcountinhibit_ctrl.Name            = ZICSRType::mcountinhibit;
//     assign mcountinhibit_ctrl.DefaultValue    = '0;
//     assign mcountinhibit_ctrl.ReadEn          = 1'b1;
//     assign mcountinhibit_ctrl.WriteEn         = 1'b1;
//     assign mcountinhibit_ctrl.InternalWriteEn = 1'b0;
//     assign mcountinhibit_ctrl.InternalWriteData = '0;

//     // ------------------------------------------------------------
//     // mhpmevent control
//     // NOTE: event selects are currently NOT used (fixed mapping above).
//     //       For now, they are implemented as read-only zeros so software
//     //       can't "select" events that don't exist yet.
//     //       When you add configurable event selection, flip WriteEn to 1.
//     // ------------------------------------------------------------
//     `define HPM_EVENT_ZERO(N) \
//         assign mhpmevent``N``_ctrl.Name            = ZICSRType::mhpmevent``N; \
//         assign mhpmevent``N``_ctrl.DefaultValue    = '0; \
//         assign mhpmevent``N``_ctrl.ReadEn          = 1'b1; \
//         assign mhpmevent``N``_ctrl.WriteEn         = 1'b0; \
//         assign mhpmevent``N``_ctrl.InternalWriteEn = 1'b0; \
//         assign mhpmevent``N``_ctrl.InternalWriteData = '0;

//     `HPM_EVENT_ZERO(3)
//     `HPM_EVENT_ZERO(4)
//     `HPM_EVENT_ZERO(5)
//     `HPM_EVENT_ZERO(6)
//     `HPM_EVENT_ZERO(7)
//     `HPM_EVENT_ZERO(8)
//     `HPM_EVENT_ZERO(9)
//     `HPM_EVENT_ZERO(10)
//     `HPM_EVENT_ZERO(11)
//     `HPM_EVENT_ZERO(12)
//     `HPM_EVENT_ZERO(13)
//     `HPM_EVENT_ZERO(14)
//     `HPM_EVENT_ZERO(15)
//     `HPM_EVENT_ZERO(16)
//     `HPM_EVENT_ZERO(17)
//     `HPM_EVENT_ZERO(18)
//     `HPM_EVENT_ZERO(19)
//     `HPM_EVENT_ZERO(20)
//     `HPM_EVENT_ZERO(21)
//     `HPM_EVENT_ZERO(22)
//     `HPM_EVENT_ZERO(23)
//     `HPM_EVENT_ZERO(24)
//     `HPM_EVENT_ZERO(25)
//     `HPM_EVENT_ZERO(26)
//     `HPM_EVENT_ZERO(27)
//     `HPM_EVENT_ZERO(28)
//     `HPM_EVENT_ZERO(29)
//     `HPM_EVENT_ZERO(30)
//     `HPM_EVENT_ZERO(31)

//     `undef HPM_EVENT_ZERO

//     // ------------------------------------------------------------
//     // mhpmcounter control
//     // Implemented set: 3,4,5,7,8,9,10,11,12,13,14,16,17
//     // Placeholders (RO zero): 6,15,18-31
//     // ------------------------------------------------------------

//     // Implemented counters (RW + internal increment)
//     `define HPM_COUNTER_IMPL(N, next64, inc_cond) \
//         assign mhpmcounter``N``_ctrl.Name            = ZICSRType::mhpmcounter``N; \
//         assign mhpmcounter``N``_ctrl.DefaultValue    = '0; \
//         assign mhpmcounter``N``_ctrl.ReadEn          = 1'b1; \
//         assign mhpmcounter``N``_ctrl.WriteEn         = 1'b1; \
//         assign mhpmcounter``N``_ctrl.InternalWriteEn = (inc_cond); \
//         assign mhpmcounter``N``_ctrl.InternalWriteData = (next64)[`XLEN-1:0]; \
//         `ifdef XLEN_32 \
//         assign mhpmcounter``N``h_ctrl.Name             = ZICSRType::mhpmcounter``N``h; \
//         assign mhpmcounter``N``h_ctrl.DefaultValue     = '0; \
//         assign mhpmcounter``N``h_ctrl.ReadEn           = 1'b1; \
//         assign mhpmcounter``N``h_ctrl.WriteEn          = 1'b1; \
//         assign mhpmcounter``N``h_ctrl.InternalWriteEn  = (inc_cond); \
//         assign mhpmcounter``N``h_ctrl.InternalWriteData = (next64)[63:32]; \
//         `endif

//     `HPM_COUNTER_IMPL(3,  MHPMCounter3Next,  (hpm3_en  & BranchRetired))
//     `HPM_COUNTER_IMPL(4,  MHPMCounter4Next,  (hpm4_en  & JumpJRRetired))
//     `HPM_COUNTER_IMPL(5,  MHPMCounter5Next,  (hpm5_en  & ReturnRetired))
//     `HPM_COUNTER_IMPL(7,  MHPMCounter7Next,  (hpm7_en  & BranchMispredict))
//     `HPM_COUNTER_IMPL(8,  MHPMCounter8Next,  (hpm8_en  & BTBMiss))
//     `HPM_COUNTER_IMPL(9,  MHPMCounter9Next,  (hpm9_en  & RASWrong))
//     `HPM_COUNTER_IMPL(10, MHPMCounter10Next, (hpm10_en & BPClassWrong))
//     `HPM_COUNTER_IMPL(11, MHPMCounter11Next, (hpm11_en & LoadStall))
//     `HPM_COUNTER_IMPL(12, MHPMCounter12Next, (hpm12_en & StoreStall))
//     `HPM_COUNTER_IMPL(13, MHPMCounter13Next, (hpm13_en & DCacheAccess))
//     `HPM_COUNTER_IMPL(14, MHPMCounter14Next, (hpm14_en & DCacheMiss))
//     `HPM_COUNTER_IMPL(16, MHPMCounter16Next, (hpm16_en & ICacheAccess))
//     `HPM_COUNTER_IMPL(17, MHPMCounter17Next, (hpm17_en & ICacheMiss))

//     `undef HPM_COUNTER_IMPL

//     // Placeholders: read-only zeros (and spots to implement later)
//     `define HPM_COUNTER_ZERO(N) \
//         assign mhpmcounter``N``_ctrl.Name            = ZICSRType::mhpmcounter``N; \
//         assign mhpmcounter``N``_ctrl.DefaultValue    = '0; \
//         assign mhpmcounter``N``_ctrl.ReadEn          = 1'b1; \
//         assign mhpmcounter``N``_ctrl.WriteEn         = 1'b0; \
//         assign mhpmcounter``N``_ctrl.InternalWriteEn = 1'b0; \
//         assign mhpmcounter``N``_ctrl.InternalWriteData = '0; \
//         `ifdef XLEN_32 \
//         assign mhpmcounter``N``h_ctrl.Name            = ZICSRType::mhpmcounter``N``h; \
//         assign mhpmcounter``N``h_ctrl.DefaultValue    = '0; \
//         assign mhpmcounter``N``h_ctrl.ReadEn          = 1'b1; \
//         assign mhpmcounter``N``h_ctrl.WriteEn         = 1'b0; \
//         assign mhpmcounter``N``h_ctrl.InternalWriteEn = 1'b0; \
//         assign mhpmcounter``N``h_ctrl.InternalWriteData = '0; \
//         `endif

//     `HPM_COUNTER_ZERO(6)
//     `HPM_COUNTER_ZERO(15)
//     `HPM_COUNTER_ZERO(18)
//     `HPM_COUNTER_ZERO(19)
//     `HPM_COUNTER_ZERO(20)
//     `HPM_COUNTER_ZERO(21)
//     `HPM_COUNTER_ZERO(22)
//     `HPM_COUNTER_ZERO(23)
//     `HPM_COUNTER_ZERO(24)
//     `HPM_COUNTER_ZERO(25)
//     `HPM_COUNTER_ZERO(26)
//     `HPM_COUNTER_ZERO(27)
//     `HPM_COUNTER_ZERO(28)
//     `HPM_COUNTER_ZERO(29)
//     `HPM_COUNTER_ZERO(30)
//     `HPM_COUNTER_ZERO(31)

//     `undef HPM_COUNTER_ZERO

// endmodule
// `endif
