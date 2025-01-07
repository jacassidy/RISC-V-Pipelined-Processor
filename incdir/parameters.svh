// `ifndef PARAMETERS_SVH
// `define PARAMETERS_SVH

    `define WORD_SIZE 32        //Shouldnt be changed
    `define BIT_COUNT 64        //Can be used to select between 32 and 64 bit processor
    `define MEMORY_WIDTH 64     //Current implementation requires to match bit count

    `define BIT_COUNT_64        //Used to enable 64 bit mode
    `define PIPELINED           //Used to enable pipelining
    `define DEBUGGING

    // `define HARDWARE_IMPLEMENATION       //some signals are cast to x, this is a problem in simulation (when all operands are 0) 
                                            //but in hardware this would always optimize to 0

// `endif // PARAMETERS