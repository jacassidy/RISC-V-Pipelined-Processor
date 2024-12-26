//Kaden Cassidy jkc.cassidy@gmail.com 12/26/2024

//'define NAME value //use by typing 'NAME

module SingleCycleTestBench();

	singleCycleTestBenchModule #("TestCode/test.hex", "", 32) test1 ();

endmodule

module singleCycleTestBenchModule #(parameter inputFileName, outputFileName, BIT_COUNT = 32) ();
	logic clk, reset;
	logic [31:0] vector_num, errors;
	
	//////////////////////////////////
	////		Section to Change		////
	//////////////////////////////////
	
	// instantiate device under test
	noCacheCore #(.INSTRUCTION_MEMORY_FILE_NAME(inputFileName), .BIT_COUNT(BIT_COUNT)) dut (.clk, .reset);
	
	//////////////////////////////////
	////		Section to Change		////
	//////////////////////////////////
	
	//input and output vectors to be assigned and compared to inputs and outputs respectively
	// logic [inputVectorSize-1:0] inputTestvectors[10000:0];
	// logic [outputVectorSize-1:0] outputTestvectors[10000:0];
	
	// generate clock
	always begin
		clk=1; #5; clk=0; #5;
	end
		
	// at start of test, load vectors and pulse reset
	initial begin
		//Load Files
		//$readmemb(inputFileName, inputTestvectors);
		//$readmemb(outputFileName, outputTestvectors);
		
		//Reset Values
		vector_num = 0; errors = 0; reset = 1; 
		
		#17; //Wait to reset
		
		reset = 0; //Begin
	end
	
	//////////////////////////////////
	////		Section to Change		////
	//////////////////////////////////
		
	// check results on falling edge of clk
	always @(negedge clk)
		if (~reset) begin // skip during reset
		
			
			
			//next test
			vector_num = vector_num + 1;
		
		end	
		
endmodule