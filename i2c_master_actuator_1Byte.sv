module i2cM (clk, reset, wdata, i2c_target_addr, i2cwr_rdBar, rdata, i2c_data_valid, apb_data_valid, i2c_ready_busyBar, req);
	//inputs
	input clk;											//clock					
	input reset;										//reset
	input [`DATA_WIDTH-1:0] wdata; 						//write data
	input [`ADDR_WIDTH-1:0]i2c_target_addr;				//target address
	input i2cwr_rdBar;									//Write=1, Read=0;	
	input apb_data_valid;								//Data valid for data received from APB
	input req;											//device select *optional* for multiple devices 

	//output
	output reg [`DATA_WIDTH-1:0] rdata;							//read data 
	output reg i2c_data_valid;									//Data valid for data sent by I2C
	output reg i2c_ready_busyBar;								//I2C ready --Active Low


	reg [`DATA_WIDTH-1:0] ir_wdata;
	reg [`ADDR_WIDTH-1:0] ir_target_addr;
	reg ir_wr_rdBar;



endmodule : i2cM