//James Kaden Cassidy jkc.cassidy@gmail.com 12/19/2024

`include "parameters.svh"

module registerFile #(
    parameter REGISTER_COUNT,

    localparam REGISTER_SELECTION_WIDTH = $clog2(REGISTER_COUNT)
) (
    input   logic                               clk,
    input   logic                               reset,
    input   logic                               WriteEn,

    input   logic[$clog2(REGISTER_COUNT)-1:0]   rs1Adr,
    input   logic[$clog2(REGISTER_COUNT)-1:0]   rs2Adr,
    input   logic[$clog2(REGISTER_COUNT)-1:0]   rd1Adr,

    input   logic[`BIT_COUNT-1:0]               Rd1,

    output  logic[`BIT_COUNT-1:0]               Rs1,
    output  logic[`BIT_COUNT-1:0]               Rs2
);

    logic[`BIT_COUNT-1:0] register_values[REGISTER_COUNT-1:0]; //output values of registers held 

    //Defining Registers 

    assign register_values[0] = 0;

    genvar i;

    generate
        for (i = 1; i < REGISTER_COUNT; i++) begin
            flopRE #(.WIDTH(`BIT_COUNT)) flop(.clk(~clk), .reset, 
                .en(WriteEn && rd1Adr == i[REGISTER_SELECTION_WIDTH-1 : 0]), 
                .D(Rd1), .Q(register_values[i]));
        end
    endgenerate

    //Register Select
    mux #(.WIDTH(`BIT_COUNT), .INPUT_BUS_COUNT(REGISTER_COUNT)) rs1Multiplexer(rs1Adr, 
        register_values, Rs1);
    mux #(.WIDTH(`BIT_COUNT), .INPUT_BUS_COUNT(REGISTER_COUNT)) rs2Multiplexer(rs2Adr, 
        register_values, Rs2);
  
endmodule