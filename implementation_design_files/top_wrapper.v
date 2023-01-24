module top_wrapper (
	input PCLK,
	input PRESETn,
	input PENABLE,
	input [1:0] data_sel,

/*	output [7:0] PRDATA,*/
	output PREADY,
	output PSLVERR,

	inout scl,
	inout sda,
	output i2c_data_valid,
	output apb_data_valid
	);

wire ta_count_done;
wire d_count_done;
wire state_count_done;
wire [7:0] PRDATA;

reg [16:0] mem [3:0];

initial
	$readmemh("D:/CDAC2022/PP/Submission/vivado/bridge/mem_data.mem", mem);

wire i_pwrite;
wire i_pselx;
wire [6:0] i_paddr;
wire [7:0] i_pwdata;
wire i_penable;

reg [1:0] ir_data_sel_final;
reg [1:0] ir_data_sel_med;
reg ir_penable_final;
reg ir_penable_med;

assign i_penable = ir_penable_final;

assign {i_pwrite, i_pselx, i_paddr, i_pwdata} = mem [ir_data_sel_final];		

always @(posedge PCLK or negedge PRESETn) begin
	if(~PRESETn) begin
		ir_data_sel_final <= 'd0;
		ir_data_sel_med <= 'd0;
		ir_penable_med <= 'd0;
		ir_penable_final <= 'd0;
	end else begin
		{ir_data_sel_final, ir_data_sel_med} <= {ir_data_sel_med, data_sel};
		{ir_penable_final, ir_penable_med} <= {ir_penable_med, PENABLE};
	end
end

apb_i2c_bridge inst_apb_i2c_bridge
	(
		.PCLK             (PCLK),
		.PRESETn          (PRESETn),
		.PWRITE           (i_pwrite),
		.PSELx            (i_pselx),
		.PENABLE          (i_penable),
		.PADDR            (i_paddr),
		.PWDATA           (i_pwdata),
		.PRDATA           (PRDATA),
		.PREADY           (PREADY),
		.PSLVERR          (PSLVERR),
		.scl              (scl),
		.sda              (sda),
		.i2c_data_valid   (i2c_data_valid),
		.apb_data_valid   (apb_data_valid),
		.ta_count_done    (ta_count_done),
		.d_count_done     (d_count_done),
		.state_count_done (state_count_done)
	);


endmodule