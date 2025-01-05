//James Kaden Cassidy jkc.cassidy@gmail.com 12/20/2024

module vectorStorage #(
    parameter MEMORY_FILE_PATH = "",
    parameter MEMORY_SIZE_WORDS,
    parameter ADRESS_SIZE,
    parameter BIT_COUNT
) (
    input   logic                       clk,
    input   logic                       reset,
    
    input   logic                       En,
    input   logic                       WriteEn,
    input   logic[(BIT_COUNT/8)-1:0]    ByteEn,

    input   logic[ADRESS_SIZE-1:0]      MemoryAdress,
    input   logic[BIT_COUNT-1:0]        InputData,

    output  logic[BIT_COUNT-1:0]        MemData
);

    logic[BIT_COUNT-1:0] Memory[MEMORY_SIZE_WORDS-1:0];

    assign MemData = En ? Memory[MemoryAdress>>2] : 'x;

    always_ff @(posedge clk) begin
        if (reset) begin

            for (int i = 0; i < MEMORY_SIZE_WORDS; i++) begin
                Memory[i] <= 'x;
            end

        end else if (WriteEn && En) begin
            logic[BIT_COUNT-1:0] LocalMemData;

            LocalMemData = Memory[MemoryAdress>>2];

            for (int i = 0; i < (BIT_COUNT/8); i++) begin
                if (ByteEn[i]) begin
                    LocalMemData[((i+1)*8-1) -: 8] = InputData[((i+1)*8-1) -: 8];
                end
            end
        
            Memory[MemoryAdress>>2] <= LocalMemData;
        end 
    end


    initial begin
        if (MEMORY_FILE_PATH !== "") begin
            $readmemh(MEMORY_FILE_PATH, Memory);
            $display("Read File" + MEMORY_FILE_PATH);
        end
    end
    
endmodule