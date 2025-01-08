## Overview
This project is an application of my knowledge in computer architecture. I used SystemVerilog to create a 5-stage pipelined processor implementing the RISC_V 64 and 32 bit instruction sets. I designed this processor with the intent of minimizing hardware without expensing speed. The processor compilation can be modified in the `parameters.svh` file located in `incdir` and supports single cycle, pipelined, 32/64 bit and debug modes to support different configurations and to ease debugging. 

## Processor Architecture
![Processor Architecture](diagrams/Architecture.jpg)
*Datapaths for instruction types and hazards below*

## Properties
- **Instruction Set:** RISC-V RV32I or RV64I
  - *ECall and EBreak currently not implemented*
  - *Fence and Pause implemented as nop instructions*
- **Pipeline Stages:** 5 or single cycle
- **Cache Design:** No cache currently implemented
  - *Current implementation requires two separate memories*
  - *Instruction memory must be 32 bit and data memory width is currently required to match bit count*
- **Branch Prediction:** No branch prediction currently implemented
   - *Support exists for the addition of branch prediction via `PCUpdateHandler.sv`
  
## Testing and Validation
I used Questa to test and validate my design. Located in the `testing` directory there exists `Testbenches` and `TestCode` directories that contain testbenches and assembly programs/expected results respectively. I used two shell scripts (also located in this directory): `assemble32.sh` and `assembly64.sh` to compile the assembly into hex. The scripts can be used with the command `./assemble__.sh path/to/assembly.s`

The Full Program testbench works on any configuration as it simply checks the final result, to use the Rd1 Lockstep testbench the proper test must be uncommented at the top of the file.

## Data Paths and Hazards
Below are diagrams highlighting the datapath for each instruction type and the signals used to handle hazards

   ![R-Type Data Path](diagrams/R_Type.jpg)
   ![I-Type Data Path](diagrams/I_Type.jpg)
   ![L-Type Data Path](diagrams/L-Type.jpg)
   ![S-Type Data Path](diagrams/S-Type.jpg)
   ![U-Type Data Path](diagrams/U_Type.jpg)
   ![J-Type Data Path](diagrams/J_Type.jpg)
   ![B-Type Data Path](diagrams/B_Type.jpg)
   ![Computational Hazard Signals](diagrams/Computational_Hazard.jpg)
   ![Load Hazard Signals](diagrams/Load_Hazard.jpg)
   ![Load After Computational Hazard Signals](diagrams/LoadAfterComputational_Hazard.jpg)
   ![Jump Hazard Signals](diagrams/Jump_Hazard.jpg)
   ![Branch Hazard Signals](diagrams/Branch_Hazard.jpg)
   ![Blank](diagrams/Blank.jpg)



