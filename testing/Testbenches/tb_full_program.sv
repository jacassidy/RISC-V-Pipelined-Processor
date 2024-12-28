//Kaden Cassidy jkc.cassidy@gmail.com 12/26/2024

//Rd1 lockstep testbench
module SingleCycleTestBench();

	singleCycleTestBenchModule #(.inputFileName("../TestCode/full_program.hex"), .output_value(32'h0f), .BIT_COUNT(32)) test1 ();

endmodule

module singleCycleTestBenchModule #(
	parameter inputFileName, 
	parameter output_value, 
	parameter BIT_COUNT = 32
) (

);
	logic clk, reset;
	logic result;
	logic [31:0] vector_num, errors, instuction_number;
	
	//////////////////////////////////
	////		Section to Change		////
	//////////////////////////////////

	//localvariables
	// localparam inputVectorSize = (3 + bitCount * 2);
	localparam outputVectorSize = (32);
	
	// instantiate device under test
	doubleMemoryCore #(.INSTRUCTION_MEMORY_FILE_NAME(inputFileName), .BIT_COUNT(BIT_COUNT)) dut (.clk, .reset);
	
	//////////////////////////////////
	////		Section to Change		////
	//////////////////////////////////
	
	//input and output vectors to be assigned and compared to inputs and outputs respectively
	// logic [inputVectorSize-1:0] inputTestvectors[10000:0];
	// logic [outputVectorSize-1:0] outputTestvectors[50:0];
	
	// generate clock
	always begin
		clk=1; #5; clk=0; #5;
	end
		
	// at start of test, load vectors and pulse reset
	initial begin
		//Load Files
		//$readmemb(inputFileName, inputTestvectors);
		// $readmemh(outputFileName, outputTestvectors);
		
		//Reset Values
		vector_num = 1; errors = 0; reset = 1; 
		
		#17; //Wait to reset
		
		reset = 0; //Begin
	end
	
	//////////////////////////////////
	////		Section to Change		////
	//////////////////////////////////

	assign instuction_number = (dut.InstrAdr >> 2) + 1;
		
	// check results on falling edge of clk
	always @(negedge clk)
		if (~reset) begin // skip during reset

			//No more instructions
			if (dut.InstructionMemory.MemData === 'x) begin
				$display("Ran out of Instructions");
				$stop;
			end

			//Check if correct result was computed
			if(dut.MemEn && dut.MemWrite && dut.MemAdr === 32'hC) begin
				if(dut.MemWriteData === output_value) begin
					$display("Correct value computed!");
				end else begin
					$display("Test Failed, Returned %d (Expected %d)", dut.MemWriteData, output_value);
				end
				$stop;
			end
			
			//next test
			vector_num = vector_num + 1;
		
		end	
		
endmodule