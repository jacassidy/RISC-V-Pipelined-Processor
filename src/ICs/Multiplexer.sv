//James Kaden Cassidy jkc.cassidy@gmail.com 12/20/2024

// module mux #(
//     parameter WIDTH = 32,
//     parameter INPUT_BUS_COUNT
// ) (
//     input logic[$clog2(INPUT_BUS_COUNT)-1:0]    selection,
//     input logic[WIDTH-1:0]                      input_busses[INPUT_BUS_COUNT-1:0],

//     output logic[WIDTH-1:0]                     selected_data
// );
//     localparam SELECTION_BUS_WIDTH = $clog2(INPUT_BUS_COUNT);

//     always_comb begin 

//         selected_data = 0;

//         for(int i = 0; i < INPUT_BUS_COUNT; i++) begin
//             if(selection == i[SELECTION_BUS_WIDTH-1:0]) selected_data = input_busses[i];
//         end
        
//     end
    
// endmodule