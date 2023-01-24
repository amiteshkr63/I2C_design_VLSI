module i2c_trial_top (
	input clk,    				//clock		
	input rst_n,  				//active low reset
	input [7:0] wdata, 			//write data
	input [6:0] addr,			//address
	input write,				//write(1) or read(0)
	input dv,					//data valid from apb
	//counter related signals
	output reg [2:0] d_count,
	output reg [3:0] a_count,
	//error 
	output i2c_error,
	//ready
	output i2c_ready,
	//read data
	output [7:0] i2c_rdata,
	//data valid for apb
	output i2c_data_valid,
	//scl
	output scl,
	//sda
	inout sda
	);

	//internal wires
	wire in_sda;
	wire out_sda;
	wire a_count_done;
	wire d_count_done;
	

	reg sda_med;
	wire aLsyncResetOut;
	
	//async reset synchronizer
	asyncLowR inst_asyncLowR (.aRLowIn(rst_n), .Clk(clk), .aLsyncResetOut(aLsyncResetOut));

	//i2c base module instance
	i2c_trial inst_i2c_trial
		(
			.clk            (clk),
			.rst_n          (aLsyncResetOut),
			.wdata          (wdata),
			.addr           (addr),
			.write          (write),
			.dv             (dv),
			.in_sda         (in_sda),
			.d_count        (d_count),
			.a_count        (a_count),
			.a_count_done   (a_count_done),
			.d_count_done   (d_count_done),
			.out_sda        (out_sda),
			.scl            (scl),
			.rdata          (i2c_rdata),
			.i2c_ready      (i2c_ready),
			.i2c_error     (i2c_error),
			.i2c_data_valid (i2c_data_valid)
		);

	//sda inout handling
	assign sda = sda_med;
	assign in_sda = sda; 

	always_comb begin
		if(!aLsyncResetOut) begin
			sda_med <= 'dz;
		end else if (a_count_done) begin
			sda_med <= 'dz;
		end else begin
			if (out_sda) begin
				sda_med <= 'dz;
			end else sda_med <= 'd0;
		end
	end

endmodule : i2c_trial_top

//async reset synchronizer 
module asyncLowR (aRLowIn, Clk, aLsyncResetOut);
	input aRLowIn, Clk;
	output reg aLsyncResetOut;
	reg temp;

	always @(posedge Clk, negedge aRLowIn) begin
		if(!aRLowIn) begin
			 {aLsyncResetOut, temp}<= 2'h0;
		end else begin
			 {aLsyncResetOut, temp}<= {temp,1'h1};
		end
	end

endmodule : asyncLowR