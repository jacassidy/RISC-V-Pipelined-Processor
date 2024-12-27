//Kaden Cassidy jkc.cassidy@gmail.com 12/26/2024

//Rd1 lockstep testbench
module SingleCycleTestBench();

	//singleCycleTestBenchModule #("../TestCode/test.hex", "../TestCode/expected_outputs.hex", 32) test1 ();
	singleCycleTestBenchModule #("../TestCode/full_RV32I.hex", "../TestCode/expected_full_RV32I_outputs.hex", 32) test1 ();

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
	localparam outputVectorSize = (32);
	
	// instantiate device under test
	noCacheCore #(.INSTRUCTION_MEMORY_FILE_NAME(inputFileName), .BIT_COUNT(BIT_COUNT)) dut (.clk, .reset);
	
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
		vector_num = 1; errors = 0; reset = 1; 
		
		#17; //Wait to reset
		
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