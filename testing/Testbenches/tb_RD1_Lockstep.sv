//Kaden Cassidy jkc.cassidy@gmail.com 12/26/2024

`include "parameters.svh"

//Rd1 lockstep testbench
module RD1_Lockstep_TestBench();

	//singleCycleTestBenchModule #("../TestCode/RD1_Lockstep/full_RV32I.hex", "../TestCode/RD1_Lockstep/expected_full_RV32I_outputs.hex", 32) test1 ();
	
	//Full RV32I chronological test
	singleCycleTestBenchModule #("../TestCode/RD1_Lockstep/Chronological_Instructions/rv32i_chronological.hex", 
								"../TestCode/RD1_Lockstep/Chronological_Instructions/expected_rv32i_chronological.hex", 32) rv32i_chronological ();

	//Full RV64I chronological test
	// singleCycleTestBenchModule #("../TestCode/RD1_Lockstep/Chronological_Instructions/rv64i_chronological.hex", 
	// 							"../TestCode/RD1_Lockstep/Chronological_Instructions/expected_rv64i_chronological.hex", 64) rv64i_chronological ();

endmodule

module singleCycleTestBenchModule #(parameter inputFileName, outputFileName, BIT_COUNT = 32) ();
	logic clk, reset;
	logic result;
	logic [31:0] vector_num, errors;
	
	//////////////////////////////////
	////		Section to Change		////
	//////////////////////////////////

	//localvariables
	// localparam inputVectorSize = (3 + bitCount * 2);
	localparam outputVectorSize = (`BIT_COUNT);
	
	// instantiate device under test
	doubleMemoryCore #(.INSTRUCTION_MEMORY_FILE_NAME(inputFileName)) dut (.clk, .reset);
	
	//////////////////////////////////
	////		Section to Change		////
	//////////////////////////////////
	
	//input and output vectors to be assigned and compared to inputs and outputs respectively
	// logic [inputVectorSize-1:0] inputTestvectors[10000:0];
	logic [outputVectorSize-1:0] outputTestvectors[50:0];
	
	// generate clock
	always begin
		clk=1; #5; clk=0; #5;
	end
		
	// at start of test, load vectors and pulse reset
	initial begin
		//Load Files
		//$readmemb(inputFileName, inputTestvectors);
		$readmemh(outputFileName, outputTestvectors);
		
		//Reset Values
		vector_num = 0; errors = 0; reset = 1; 
		
		#12; //Wait to reset
		
		reset = 0; //Begin
	end
	
	//////////////////////////////////
	////		Section to Change		////
	//////////////////////////////////
		
	// check results on falling edge of clk
	always @(negedge clk)
		if (~reset) begin // skip during reset

			//No more instructions
			if (dut.InstructionMemory.MemData === 'x) begin
				$display("Total test cases %d", vector_num);
				$display("Total errors %d", errors);
				$stop;
			end

			//Check if correct result was computed
			if(dut.ComputeCore.RegisterFile.Rd1 === outputTestvectors[vector_num]) begin
				result = 1'b1;
			end else begin
				if (outputTestvectors[vector_num] === 'x) begin
					result = 1'b0;
				end else begin
					result = 1'bx;
					errors = errors + 1;
				end
			end
			
			//next test
			vector_num = vector_num + 1;
		
		end	
		
endmodule