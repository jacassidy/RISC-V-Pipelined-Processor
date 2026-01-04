//James Kaden Cassidy jkc.cassidy@gmail.com 12/19/2024

`include "parameters.svh"

module flopR #(
    WIDTH   = 32,
    DEFAULT = 0
) (
    input   logic               clk,
    input   logic               reset,
    input   logic[WIDTH-1:0]    D,

    output  logic[WIDTH-1:0]    Q
);

    always_ff @( posedge clk ) begin
        if (reset)  Q <= DEFAULT;
        else        Q <= D;
    end

endmodule

module flopNR #(
    WIDTH   = 32,
    DEFAULT = 0
) (
    input   logic               clk,
    input   logic               reset,
    input   logic[WIDTH-1:0]    D,

    output  logic[WIDTH-1:0]    Q
);

    always_ff @( negedge clk ) begin
        if (reset)  Q <= DEFAULT;
        else        Q <= D;
    end

endmodule

module flopRE #(
    WIDTH   = 32,
    DEFAULT = 0
) (
    input   logic               clk,
    input   logic               reset,
    input   logic               en,
    input   logic[WIDTH-1:0]    D,

    output  logic[WIDTH-1:0]    Q
);

    always_ff @( posedge clk ) begin
        if (reset)      Q <= DEFAULT;
        else if (en)    Q <= D;
    end

endmodule

module flopNRE #(
    WIDTH   = 32,
    DEFAULT = 0
) (
    input   logic               clk,
    input   logic               reset,
    input   logic               en,
    input   logic[WIDTH-1:0]    D,

    output  logic[WIDTH-1:0]    Q
);

    always_ff @( negedge clk ) begin
        if (reset)      Q <= DEFAULT;
        else if (en)    Q <= D;
    end

endmodule

module flopRS #(
    WIDTH   = 32,
    DEFAULT = 0
) (
    input   logic               clk,
    input   logic               reset,
    input   logic               stall,
    input   logic[WIDTH-1:0]    D,

    output  logic[WIDTH-1:0]    Q
);

    always_ff @( posedge clk ) begin
        if (reset)          Q <= DEFAULT;
        else if (~stall)    Q <= D;
    end

endmodule

module flopRF #(
    WIDTH   = 32,
    DEFAULT = 0
) (
    input   logic               clk,
    input   logic               reset,
    input   logic               flush,
    input   logic[WIDTH-1:0]    D,

    output  logic[WIDTH-1:0]    Q
);

    always_ff @( posedge clk ) begin
        if (reset)  Q <= DEFAULT;
        else begin
            if (flush)  Q <= DEFAULT;
            else        Q <= D;
        end
    end

endmodule

module flopRFS #(
    WIDTH   = 32,
    DEFAULT = 0
) (
    input   logic               clk,
    input   logic               reset,
    input   logic               stall,
    input   logic               flush,
    input   logic[WIDTH-1:0]    D,

    output  logic[WIDTH-1:0]    Q
);

    always_ff @( posedge clk ) begin
        if (reset)  Q <= DEFAULT;
        else if (~stall) begin
            if (flush)  Q <= DEFAULT;
            else        Q <= D;
        end
    end

endmodule

`ifdef ZICSR
module flopCSR #(
    WIDTH   = 32
) (
    input   logic                   clk,
    input   logic                   reset,
    input   logic[WIDTH-1:0]        reset_val,

    input   logic                   OpEn,
    input   HighLevelControl::csrOp Op,
    input   logic[WIDTH-1:0]        OpD,

    input   logic                   WriteEn,
    input   logic[WIDTH-1:0]        WriteD,

    output  logic[WIDTH-1:0]        Q
);

    always_ff @( posedge clk ) begin
        if (reset)  Q <= reset_val;
        else if (OpEn) begin
            casex (Op)
                HighLevelControl::Write:    Q <= OpD;
                HighLevelControl::Set:      Q <= Q | OpD;
                HighLevelControl::Clear:    Q <= Q & ~OpD;
                HighLevelControl::Read:     ;
                default: begin
                    $display("Invalid CSR flop operation");
                    $finish(-1);
                end
            endcase
        end else if (WriteEn) begin
            Q <= WriteD;
        end
    end

endmodule
`endif
