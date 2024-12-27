//James Kaden Cassidy jkc.cassidy@gmail.com 12/20/2024

`define WORD_SIZE 32

module vectorStorage #(
    parameter MEMORY_FILE_PATH = "",
    parameter MEMORY_SIZE_WORDS,
    parameter ADRESS_SIZE
) (
    
    input   logic                       MemEn,
    input   logic                       WriteEnable,
    input   logic[(`WORD_SIZE/8)-1:0]   ByteEn,

    input   logic[ADRESS_SIZE-1:0]      MemoryAdress,
    input   logic[`WORD_SIZE-1:0]       InputData,

    output  logic[`WORD_SIZE-1:0]       MemData
);

    logic[`WORD_SIZE-1:0] Memory[MEMORY_SIZE_WORDS-1:0];

    assign MemData = MemEn ? Memory[MemoryAdress>>2] : 'x;

    always_latch begin
        if (WriteEnable & MemEn) begin
            for (int i = 0; i < (`WORD_SIZE/8); i++) begin
                logic[`WORD_SIZE-1:0] LocalMemData;
                LocalMemData = Memory[MemoryAdress>>2];
                if (ByteEn[i]) begin
                    LocalMemData[(i+1)*8 -: 8] <= InputData[(i+1)*8 -: 8];
                end
            end
        end
    end

    initial begin
        if (MEMORY_FILE_PATH !== "") begin
            $readmemh(MEMORY_FILE_PATH, Memory);
            $display("Read File" + MEMORY_FILE_PATH);
        end
    end
    
endmodule