`ifndef PARAMETERS_SVH
`define PARAMETERS_SVH

    `define XLEN_32
    //`define XLEN_64        //Used to enable 64 bit mode
    `define MEMORY_WIDTH 32     //Current implementation requires to match bit count (TODO does not handle memory correctly esp instructions)
    `define PIPELINED           //Used to enable pipelining
    //`define DEBUGGING

    `define WORD_SIZE 32        //Shouldnt be changed

    `ifdef XLEN_32
        `define XLEN 32        //Can be used to select between 32 and 64 bit processor
    `elsif XLEN_64
        `define XLEN 64
    `endif

`endif // PARAMETERS
