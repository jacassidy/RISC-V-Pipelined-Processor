//Kaden Cassidy jkc.cassidy@gmail.com 12/26/2024

`include "parameters.svh"

//Rd1 lockstep testbench
module RD1_Lockstep_TestBench();

	//Supposed to be all RV32I instructions
	// localparam inputFileName 	="../TestCode/RD1_Lockstep/full_RV32I.hex";
	// localparam outputFileName 	= "../TestCode/RD1_Lockstep/expected_full_RV32I_outputs.hex";
	// localparam BIT_COUNT 		= 32;
	
	//Full RV32I chronological test
	// localparam inputFileName 	= "../TestCode/RD1_Lockstep/Chronological_Instructions/rv32i_chronological.hex"; 
	// localparam outputFileName 	= "../TestCode/RD1_Lockstep/Chronological_Instructions/expected_rv32i_chronological.hex"; 
	// localparam BIT_COUNT 		= 32;

	//Full RV64I chronological test
	// localparam inputFileName 		= "../TestCode/RD1_Lockstep/Chronological_Instructions/rv64i_chronological.hex";
	// localparam outputFileName 		= "../TestCode/RD1_Lockstep/Chronological_Instructions/expected_rv64i_chronological.hex";
	// localparam BIT_COUNT 			= 64;

	//Full Pipelined RV32I chronological test
	// localparam inputFileName 	= "../TestCode/RD1_Lockstep/Chronological_Instructions/rv32i_chronological.hex"; 
	// localparam outputFileName 	= "../TestCode/RD1_Lockstep/Chronological_Instructions/expected_pipelined_rv32i_chronological.hex"; 
	// localparam BIT_COUNT 		= 32;

	//Full Pipelined RV64I chronological test
	localparam inputFileName 		= "../TestCode/RD1_Lockstep/Chronological_Instructions/rv64i_chronological.hex";
	localparam outputFileName 		= "../TestCode/RD1_Lockstep/Chronological_Instructions/expected_pipelined_rv64i_chronological.hex";
	localparam BIT_COUNT 			= 64;

	logic clk, reset;
	logic result;
	logic [31:0] vector_num, errors;
	logic[`BIT_COUNT-1:0] ExpectedRd1;
	integer line_count = 0;
	
	//localvariables
	// localparam inputVectorSize = (3 + bitCount * 2);
	localparam outputVectorSize = (`BIT_COUNT);
	
	// instantiate device under test
	doubleMemoryCore #(.INSTRUCTION_MEMORY_FILE_NAME(inputFileName)) dut (.clk, .reset);
	
	//input and output vectors to be assigned and compared to inputs and outputs respectively
	// logic [inputVectorSize-1:0] inputTestvectors[10000:0];
	logic [outputVectorSize-1:0] outputTestvectors[10000:0];
	
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
		
	// check results on falling edge of clk
	always @(negedge clk)
		if (~reset) begin // skip during reset

			ExpectedRd1 = outputTestvectors[vector_num];

			//No more instructions
			if (vector_num == line_count) begin
				$display("Total test cases %d", vector_num);
				$display("Total errors %d", errors);
				$stop;
			end

			//Check if correct result was computed
			if(dut.ComputeCore.RegisterFile.Rd1 === ExpectedRd1) begin
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

	integer fd;
	integer r;
	reg [1023:0] line;  // Buffer for reading one line at a time

	initial begin
		fd = $fopen(outputFileName, "r");
		if (fd == 0) begin
			$display("ERROR: Could not open file.");
			$finish;
		end

		// Read until end-of-file
		while (!$feof(fd)) begin
			// $fgets returns 0 on error or end-of-file
			r = $fgets(line, fd);
			if (r != 0)
				line_count++;
		end
		$fclose(fd);
	end
			
endmodule