module core #(
    WORD_SIZE = 32
) (
    input logic clk,
    input logic reset,

    //To handle memory / chache externally
    output logic[WORD_SIZE-1 : 0] PC,       //Instruction Cache
    output logic[WORD_SIZE-1 : 0] ALUResult, //Memory Cache
    output logic[WORD_SIZE-1 : 0] ____,      //Memory to be saved

    input logic[WORD_SIZE-1 : 0] Instr,
    input logic[WORD_SIZE-1 : 0] MemData,
);

    logic logic[WORD_SIZE-1 : 0] PCNext, ;

    //Program Counter
    flopR #(WIDTH = WORD_SIZE) ProgramCounter(.clk, .reset, .D(PCNext), .Q(PC));

    //Instuction handline controlled externally


    
endmodule