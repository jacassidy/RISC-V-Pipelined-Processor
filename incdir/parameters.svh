`ifndef PARAMETERS_SVH
`define PARAMETERS_SVH

    //`define PIPELINED

    `define XLEN_32
    //`define XLEN_64        //Used to enable 64 bit mode
    `define MEMORY_WIDTH 32     //Current implementation requires to match bit count (TODO does not handle memory correctly esp instructions)
               //Used to enable pipelining

    `define ZICSR

    `define ZICNTR
    `define ZIHPM

    //`define DEBUGGING
    `define DEBUG_PRINT

    // Derived / Permanent signals

    `define WORD_SIZE 32
    `define CSR_ADDRESS_SPACE 4096

    `ifdef XLEN_32
        `define XLEN 32
        `define XLENlg2 5
    `elsif XLEN_64
        `define XLEN 64
        `define XLENlg2 6
    `endif

    `define CSR_LIST(X) \
        `X(ustatus,  12'h000) \
        `X(mstatus,  12'h300) \
        `X(mtvec,    12'h305) \
        `X(mhartid,  12'hF14) \
        `ifdef ZICNTR \
        `X(minsret,  12'hB02) \
        `X(rdcycle,  12'hC00) \
        `X(rdtime,   12'hC01) \
        `X(rdinsret, 12'hC02) \
            `ifdef XLEN_32 \
            `X(rdcycleh, 12'hC80) \
            `X(rdtimeh,  12'hC81) \
            `X(rdinsreth,12'hC82) \
            `endif \
        `endif


`endif // PARAMETERS
