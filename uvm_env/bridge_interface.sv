interface bridge_interface #(parameter ADDR_WIDTH= 7, DATA_WIDTH = 8) (input bit Pclk);
	//inputs
	logic Presetn;
	logic Pselx;
	logic Pwrite;
	logic Penable;
	logic [ADDR_WIDTH-1:0] Paddr;
	logic [DATA_WIDTH-1:0] Pwdata;

	//outputs
	logic Pready;
	logic Pslverr;
	logic [DATA_WIDTH-1:0] Prdata;
	wire sda;
	logic sda_flag=1;
	wire scl;
	logic [2:0] d_count;
	logic [3:0] a_count;
	logic i2c_data_valid;
	logic apb_data_valid;


	assign sda = sda_flag?'dz:'d0;

	clocking cb@(posedge Pclk);
		default input #1 output #1;
		//inputs
		output Pselx;
		output Pwrite;
		output Penable;
		output Paddr;
		output Pwdata;
		
		//outputs
		input Pready;
		input Pslverr;
		input Prdata;
		input scl;
		inout sda;
		input i2c_data_valid;
		input apb_data_valid;
		input d_count;
		input a_count;
	endclocking

	clocking cb_mon@(posedge Pclk);
		default input #1 output #1;

		//inputs
		input Pselx;
		input Pwrite;
		input Penable;
		input Paddr;
		input Pwdata;
		
		//outputs
		input Pready;
		input Pslverr;
		input Prdata;
		input scl;
		inout sda;
		input i2c_data_valid;
		input apb_data_valid;
		input d_count;
		input a_count;
	endclocking

	modport MP (clocking cb, input Pclk, output Presetn);		    //modport
	modport IP (clocking cb_mon, input Pclk, input Presetn);		//modport

endinterface

