module registerFile #(
    parameter WORD_SIZE,
    parameter REGISTER_COUNT
) (
    input logic clk,
    input logic reset,
    input logic WriteEnable,

    input logic[$clog2(REGISTER_COUNT)-1 : 0] rs1Adr,
    input logic[$clog2(REGISTER_COUNT)-1 : 0] rs2Adr,
    input logic[$clog2(REGISTER_COUNT)-1 : 0] rd1Adr,

    input logic[WORD_SIZE-1 : 0] Rd1,

    output logic[WORD_SIZE-1 : 0] Rs1,
    output logic[WORD_SIZE-1 : 0] Rs2
);
    localparam REGISTER_SELECTION_WIDTH = $clog2(REGISTER_COUNT);

    logic [WORD_SIZE-1 : 0] register_values[REGISTER_COUNT]; //output values of registers held 

    //Defining Registers 

    generate
        for (int i = 0; i < REGISTER_COUNT; i++) begin
            flopRE #(WIDTH = WORD_SIZE) flop(.clk, .reset, 
                .en(WriteEnable && rd1Adr === logic'(i)[REGISTER_SELECTION_WIDTH-1 : 0]), 
                .D(Rd1), .Q(register_values[i]));
        end
    endgenerate

    //Register Select
    mux #(WIDTH = WORD_SIZE, INPUT_BUS_COUNT = REGISTER_COUNT) rs1Multiplexer(rs1Adr, 
        register_values, Rs1);
    mux #(WIDTH = WORD_SIZE, INPUT_BUS_COUNT = REGISTER_COUNT) rs2Multiplexer(rs2Adr, 
        register_values, Rs2);
  
endmodule