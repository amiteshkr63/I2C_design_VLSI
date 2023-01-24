module top (
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low
	input [6:0]i_taaddr6_0,
	input i_apb_dv,
	input i_write,
	input [7:0]i_wdata,							//One Block Write
	output or_act_rdbsybar,
	output wire ta_count_done,
	output wire d_count_done,
	output wire state_count_done,
	output o_i2c_dv,
	output wire o_i2c_err,
	////////////////////////////		
	inout scl,
	inout sda
	///////////////////////////
);
	//////////////
	wire out_sda;
	wire in_sda;
	/////////////

	wire [9:0]state_count;
	wire [2:0]ta_count;
	wire [2:0]d_count;
	wire o_act_stop_idle_flag;
	reg sda_med;
    wire aLsyncResetOut;
	i2c_actuator inst_i2c_actuator
		(
			.clk                 (clk),
			.rst_n               (aLsyncResetOut),
			.i_taaddr6_0         (i_taaddr6_0),
			.in_sda              (in_sda),
			.i_write_n            (aLwriteOut),
			.i_wdata             (i_wdata),
			.i_apb_dv_n            (aapbdvOut),/////////////////
			.o_scl               (scl),
			.out_sda             (out_sda),
			.o_i2c_err           (o_i2c_err),
			.state_count         (state_count),
			.ta_count            (ta_count),
			.d_count             (d_count),
			.ta_count_done       (ta_count_done),
			.d_count_done        (d_count_done),
			.state_count_done    (state_count_done),
			.o_act_stop_idle_flag (o_act_stop_idle_flag),
			.or_act_rdbsybar   (or_act_rdbsybar)
		);

	asynwriteR asynwriteR_inst (.awriteIn(~i_write), .clk(clk), .aLwriteOut(aLwriteOut));
	asyncLowR asyncLowR_inst(.aRLowIn(rst_n), .clk(clk), .aLsyncResetOut(aLsyncResetOut));
	asyncapbvalid asyncapbvalid_inst (.aapbdvIn(~i_apb_dv), .clk(clk), .aapbdvOut(aapbdvOut));
	assign o_i2c_dv=0;
	assign sda = sda_med?'dz:'d0;
	assign in_sda = sda;
	always_comb begin
		if(~aLsyncResetOut) begin
			sda_med <= 'd1;
		end else if ((ta_count_done && (~state_count_done)) || (d_count_done && (~state_count_done))) begin
			sda_med <= 'd0;
		end else begin
			sda_med <= out_sda;
		end
	end

endmodule : top

module asyncLowR (aRLowIn, clk, aLsyncResetOut);
	input aRLowIn, clk;
	output reg aLsyncResetOut;
	reg temp;
	always @(posedge clk, negedge aRLowIn) begin
		if(!aRLowIn) begin
			 {aLsyncResetOut, temp}<= 2'b0;
		end else begin
			 {aLsyncResetOut, temp}<= {temp,1'b1};
		end
	end
endmodule

module asynwriteR (awriteIn, clk, aLwriteOut);
	input awriteIn, clk;
	output reg aLwriteOut;
	reg temp;
	always @(posedge clk, negedge awriteIn) begin
		if(!awriteIn) begin
			 {aLwriteOut, temp}<= 2'b0;
		end else begin
			 {aLwriteOut, temp}<= {temp,1'b1};
		end
	end
endmodule

module asyncapbvalid (aapbdvIn, clk, aapbdvOut);
	input aapbdvIn, clk;
	output reg aapbdvOut;
	reg temp;
	always @(posedge clk, negedge aapbdvIn) begin
		if(!aapbdvIn) begin
			 {aapbdvOut, temp}<= 2'b0;
		end else begin
			 {aapbdvOut, temp}<= {temp,1'b1};
		end
	end
endmodule