module apb_i2c_bridge(
	input PCLK,				       	//clock						
	input PRESETn,					//reset active low
	input PWRITE,					//write/read control
	input PSELx,					//select control from master
	input PENABLE,					//control from master, Enable
	input [6:0] PADDR,				//Address from master
	input [7:0] PWDATA,				//write data from master

	output reg [7:0] PRDATA,		//read data to master
	output reg PREADY,				//ready signal to master
	output reg PSLVERR,				//error signal to master

	output scl,						//scl for i2c 
	inout sda,						//sda for i2c
	output i2c_data_valid,			//data valid from i2c
	output apb_data_valid,			//data valid to i2c
	output ta_count_done,
	output d_count_done,
	output state_count_done
);

//internal wires
wire i2c_ready, i2c_error;          								
wire [7:0] i2c_rdata;
assign i2c_rdata = 0;  									

wire [6:0] i2c_addr; 						
wire [7:0] i2c_wdata; 								
wire i2c_write;                 					

//apb slave instance
	apb_controller inst_apb_controller
		(
			.PCLK           (PCLK),
			.PRESETn        (PRESETn),
			.PWRITE         (PWRITE),
			.PSELx          (PSELx),
			.PENABLE        (PENABLE),
			.PADDR          (PADDR),
			.PWDATA         (PWDATA),
			.PREADY         (PREADY),
			.PSLVERR        (PSLVERR),
			.PRDATA         (PRDATA),
			.i2c_ready      (i2c_ready),
			.i2c_error      (i2c_error),
			.i2c_rdata      (i2c_rdata),
			.i2c_data_valid (i2c_data_valid),
			.i2c_addr       (i2c_addr),
			.i2c_wdata      (i2c_wdata),
			.i2c_write      (i2c_write),
			.apb_data_valid (apb_data_valid)
		);



//i2c instance
/*	i2c_trial_top inst_i2c_trial_top
		(
			.clk            (PCLK),
			.rst_n          (PRESETn),
			.wdata          (i2c_wdata),
			.addr           (i2c_addr),
			.write          (i2c_write),
			.dv             (apb_data_valid),
			.d_count        (d_count),
			.a_count        (a_count),
			.i2c_error      (i2c_error),
			.i2c_ready      (i2c_ready),
			.i2c_rdata      (i2c_rdata),
			.i2c_data_valid (i2c_data_valid),
			.scl            (scl),
			.sda            (sda)
		);*/

	top inst_top
		(
			.clk              (PCLK),
			.rst_n            (PRESETn),
			.i_taaddr6_0      (i2c_addr),
			.i_apb_dv         (apb_data_valid),
			.i_write          (i2c_write),
			.i_wdata          (i2c_wdata),
			.or_act_rdbsybar  (i2c_ready),
			.ta_count_done    (ta_count_done),
			.d_count_done     (d_count_done),
			.state_count_done (state_count_done),
			.o_i2c_dv         (i2c_data_valid),
			.o_i2c_err        (i2c_error),
			.scl              (scl),
			.sda              (sda)
		);






endmodule : apb_i2c_bridge