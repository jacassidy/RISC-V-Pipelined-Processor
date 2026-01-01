//James Kaden Cassidy jkc.cassidy@gmail.com 12/27/2025

`include "parameters.svh"

`ifdef ZICSR

module csrReadFile #(
) (
    input   logic                                   clk,
    input   logic                                   reset,

    // CSR access as determined by instruction (CSR read write etc.)
    input   logic                                   CSREn,
    input   HighLevelControl::csrOp                 CSROp,
    input   logic                                   CSRReadEn,

    input   logic[$clog2(`CSR_ADDRESS_SPACE)-1:0]   CSRAdr,
    input   logic[`XLEN-1:0]                        WriteData,

    // CSR access as determined by the CSR itself (Read only, Write Only etc.)
    input   wire ZICSRType::csrCtrl                 csr_control [(1 << $clog2(ZICSRType::CSR_COUNT))-1:0],

    output  logic[`XLEN-1:0]                        ReadData,

    output  wire logic[`XLEN-1:0]                   csr_values  [(1 << $clog2(ZICSRType::CSR_COUNT))-1:0]
);

    ZICSRType::validCSRs targetCSR;

    always_comb begin
        casex(CSRAdr)
            `define X(name, adr) adr: targetCSR = ZICSRType::name;
                `CSR_LIST(X)
            `undef X
            default: targetCSR = ZICSRType::validCSRs'('x);
        endcase
    end

    generate
    `define X(name, adr) \
        begin : gen_``name                                      \
        localparam ZICSRType::validCSRs csr = ZICSRType::name;  \
            flopCSR #(.WIDTH(`XLEN)) CSRFlop (                  \
                .clk, .reset,                                   \
                .reset_val (csr_control[csr].DefaultValue),     \
                .OpEn      (CSREn                               \
                            & (csr == targetCSR)                \
                            & csr_control[csr].WriteEn),        \
                .Op        (CSROp),                             \
                .OpD       (WriteData),                         \
                .WriteEn   (csr_control[csr].InternalWriteEn),  \
                .WriteD    (csr_control[csr].InternalWriteData),\
                .Q         (csr_values[csr])                    \
            );                                                  \
        end
        `CSR_LIST(X)
    `undef X
    endgenerate

    //Register Select
    always_comb begin
        if (CSREn & CSRReadEn) ReadData = csr_values[targetCSR];
        else                   ReadData = 'x;
    end

    `ifdef DEBUG_PRINT
    always_ff @(posedge clk) begin
        if (CSREn) begin
            $display("CSR %h, write_en: %b, read_en: %b, read_data: %h, internal_write_en: %b, internal_write_data: %h",
                        CSRAdr, csr_control[CSRAdr].WriteEn, csr_control[CSRAdr].ReadEn, ReadData,
                        csr_control[CSRAdr].InternalWriteEn, csr_control[CSRAdr].InternalWriteData);
        end
        if (CSREn && targetCSR === ZICSRType::validCSRs'('x)) begin
            $display("Invalid CSR address attempted to be accessed: %h", CSRAdr);
            $finish(-1);
        end
        if (CSREn && CSRReadEn) begin // attempting to read
            if (csr_control[targetCSR].ReadEn !== 1'b1) begin // includes X
                $display("Invalid CSR address attempted to be read: %h", CSRAdr);
                $finish(-1);
            end
        end
        if (CSREn && CSROp != HighLevelControl::Read) begin // attempting to written
            if (csr_control[targetCSR].WriteEn !== 1'b1) begin // includes X
                $display("Invalid CSR address attempted to be %s: %h", CSROp.name(), CSRAdr);
                $finish(-1);
            end
        end
    end
    `endif

endmodule
`endif
