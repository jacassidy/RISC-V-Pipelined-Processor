`include "parameters.svh"

module tb_evo;

	localparam int IMEM_WORDS = 4096;
	localparam int DMEM_WORDS = 4096;
	localparam int MAX_VECTORS = 10000;
	localparam int BYTE_SHIFT = $clog2(`XLEN/8);

	logic clk, reset;

	logic [`XLEN-1:0]   PC, IEUAdr, ReadData, WriteData;
	logic [31:0]        Instr;
	logic               MemEn, WriteEn;
	logic [`XLEN/8-1:0] WriteByteEn;

	logic [31:0]        imem [0:IMEM_WORDS-1];
	logic [`XLEN-1:0]   dmem [0:DMEM_WORDS-1];
	logic [`XLEN-1:0]   expect_val  [0:MAX_VECTORS-1];
	logic [`XLEN-1:0]   expect_mask [0:MAX_VECTORS-1];

	string imem_file, expect_val_file, expect_mask_file, mode, label;
	int nvec, max_cycles, vector_num, errors, cycles;
	logic [`XLEN-1:0] done_addr, done_value;

	testingCore dut(.clk, .reset, .PC, .Instr, .IEUAdr, .ReadData, .WriteData, .MemEn, .WriteEn, .WriteByteEn);

	assign Instr    = imem[PC[$clog2(IMEM_WORDS)+1:2]];
	assign ReadData = dmem[IEUAdr[$clog2(DMEM_WORDS)+BYTE_SHIFT-1:BYTE_SHIFT]];

	always_ff @(posedge clk)
		if (WriteEn && MemEn)
			for (int i = 0; i < `XLEN/8; i++)
				if (WriteByteEn[i])
					dmem[IEUAdr[$clog2(DMEM_WORDS)+BYTE_SHIFT-1:BYTE_SHIFT]][i*8 +: 8] <= WriteData[i*8 +: 8];

	always begin
		clk = 1; #5; clk = 0; #5;
	end

	task automatic finish_run(input bit passed, input string reason);
		$display("EVO_RESULT label=%s mode=%s xlen=%0d vectors=%0d errors=%0d cycles=%0d status=%s reason=%s",
			label, mode, `XLEN, vector_num, errors, cycles, passed ? "PASS" : "FAIL", reason);
		if (passed) $finish;
		else $fatal(1, "test failed: %s", reason);
	endtask

	initial begin
		for (int i = 0; i < IMEM_WORDS; i++) imem[i] = '0;
		for (int i = 0; i < DMEM_WORDS; i++) dmem[i] = '0;
		for (int i = 0; i < MAX_VECTORS; i++) begin expect_val[i] = '0; expect_mask[i] = '0; end
		if (!$value$plusargs("IMEM=%s", imem_file)) $fatal(1, "missing +IMEM");
		if (!$value$plusargs("MODE=%s", mode)) mode = "lockstep";
		if (!$value$plusargs("LABEL=%s", label)) label = "run";
		if (!$value$plusargs("MAX_CYCLES=%d", max_cycles)) max_cycles = 100000;
		if (!$value$plusargs("DONE_ADDR=%h", done_addr)) done_addr = `XLEN'hC;
		if (!$value$plusargs("DONE_VALUE=%h", done_value)) done_value = `XLEN'h0F;
		$readmemh(imem_file, imem);
		if (mode == "lockstep") begin
			if (!$value$plusargs("EXPECT_VAL=%s", expect_val_file)) $fatal(1, "missing +EXPECT_VAL");
			if (!$value$plusargs("EXPECT_MASK=%s", expect_mask_file)) $fatal(1, "missing +EXPECT_MASK");
			if (!$value$plusargs("NVEC=%d", nvec)) $fatal(1, "missing +NVEC");
			$readmemh(expect_val_file, expect_val);
			$readmemh(expect_mask_file, expect_mask);
		end
		vector_num = 0; errors = 0; cycles = 0; reset = 1;
		#12;
		reset = 0;
	end

	always @(negedge clk)
		if (~reset) begin
			cycles = cycles + 1;
			if (mode == "lockstep") begin
				if (vector_num == nvec) finish_run(errors == 0, errors == 0 ? "all_vectors_matched" : "mismatches");
				else begin
					if ((dut.ComputeCore.Rd1_W & expect_mask[vector_num]) !== (expect_val[vector_num] & expect_mask[vector_num])) begin
						errors = errors + 1;
						$display("MISMATCH vector=%0d pc=%h got=%h expected=%h mask=%h", vector_num, PC,
							dut.ComputeCore.Rd1_W, expect_val[vector_num], expect_mask[vector_num]);
					end
					vector_num = vector_num + 1;
				end
			end else begin
				if (MemEn && WriteEn && IEUAdr == (done_addr & ~((`XLEN'(1) << BYTE_SHIFT) - 1))) begin
					if (WriteData == done_value) finish_run(1, "done_store_matched");
					else begin
						errors = 1;
						$display("DONE_STORE got=%h expected=%h", WriteData, done_value);
						finish_run(0, "done_store_wrong_value");
					end
				end
				if (Instr == 32'b0) finish_run(0, "ran_out_of_instructions");
			end
			if (cycles >= max_cycles) finish_run(0, "max_cycles");
		end

endmodule
