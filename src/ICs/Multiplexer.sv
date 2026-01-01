//James Kaden Cassidy jkc.cassidy@gmail.com 12/20/2024

module mux #(
    parameter WIDTH = 32,
    parameter INPUT_BUS_COUNT
) (
    input   logic[$clog2(INPUT_BUS_COUNT)-1:0]  selection,
    input   wire logic [WIDTH-1:0]              input_busses[INPUT_BUS_COUNT-1:0],

    output  logic[WIDTH-1:0]                    selected_data
);

    assign selected_data = input_busses[selection];

endmodule
