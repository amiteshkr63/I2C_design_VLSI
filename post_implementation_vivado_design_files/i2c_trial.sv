module i2c_trial (
	input clk,    						// Clock             
	input rst_n,						//rst_n              
	input [7:0] wdata,					//write data         
	input [6:0] addr,					//addr               
	input  write,						//write or read      
	input dv,							//data valid from apb
	input in_sda,						//input sda          
//counters and related signals
	output reg [2:0] d_count,		//counter for the WDATA phase
	output reg [3:0] a_count,		//counter for the ADDR and you rd/wr phase
	output reg a_count_done,		//signal to say that ADDR is sent
	output reg d_count_done,		//signal to say that WDATA is sent

//scl and sda outputs
	output reg out_sda,				//output sda
	output scl,						//scl
//read data
	output [7:0] rdata,				//read data
//ready
	output reg i2c_ready,			//ready signal
//error
	output reg i2c_error,
//data valid for apb
	output reg i2c_data_valid		//read data is valid signal
);


//register for inputs
	reg [7:0] ir_wdata;				//internal register for wdata
	reg [6:0] ir_addr;				//internal register for addr
	reg [7:0] ir_rdata;				//internal register for read data

//read data
	assign rdata = ir_rdata;		//assigning internal register to output for rdata


//registers for counters
reg [3:0] state_counter;			//counter for each state
reg [2:0] scl_counter;				//counter for scl to switch at half of state

//states for state machine
typedef enum{IDLE, START, ADDR, ASL_ACK, WDATA, RDATA, DSL_ACK, DM_NACK, STOP} states;

states pst;

//scl
reg scl_en = 0;
assign scl = scl_en?'d0:'dz;						//scl low whenever scl_en=1 otherwise disconnected

//scl enable generation 
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		scl_en <= 'd0;
	end else begin
		if(pst == IDLE || pst == STOP)  begin
			if (scl_counter == 'd7) scl_en <= 'd0;
		end else if (pst == START) begin
			if (state_counter == 15) begin
				scl_en <= 'd1;
			end else scl_en <= 'd0;
		end  else if (pst == ASL_ACK || pst == DSL_ACK) begin
				if(state_counter == 'd15 && in_sda) scl_en <= 'd0; 
				else begin
					if(scl_counter == 'd7) scl_en <= ~scl_en;
				end 
		end else begin
			if (scl_counter == 'd7) scl_en <= ~scl_en;
		end
	end
end


//state and scl counter increament
always_ff @(posedge clk or negedge rst_n) begin : proc_
	if(~rst_n) begin
		state_counter <= 0;
		scl_counter <= 0;
	end else begin
		state_counter <= state_counter + 1;
		scl_counter <= scl_counter +1;
	end
end


//counters for wdata and addr phase 
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		a_count <= 'd8;
		d_count <= 'd7;
		d_count_done <= 0;
		a_count_done <= 0;
		
	end else begin
		//counter for ADDR state
		if (pst == START || pst == ADDR) begin
			if (state_counter == 'd15) a_count <= a_count - 'd1;
			//address state done signal
			case (a_count)
				0: begin
					 if (state_counter == 'd15) begin
					 	a_count_done <= 'd1;
					 	a_count <= 'd8;
					 end  
				end
				default : if (state_counter == 'd15)  a_count_done <= 'd0;
			endcase
		end else begin
			a_count <= 'd8;
			a_count_done <= 'd0;
		end  


		//counter for WDATA state
		if (pst == WDATA || pst == RDATA) begin
			if (state_counter == 'd15)  d_count <= d_count - 'd1;

			//data state done signal
			case (d_count)
				0: begin 
					if (state_counter == 'd15)  d_count_done <= 'd1;
				end		
				default : if (state_counter == 'd15)  d_count_done <= 'd0;
			endcase
		end else begin
			d_count <= 'd7;
			d_count_done <= 'd0;
		end 

	end
end

//pst and out_sda
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		pst <= IDLE;
		out_sda <= 'd1;
		ir_wdata <= 'd0;
		ir_addr <= 'd0;
		ir_rdata <= 'd0;
		i2c_ready <= 'd0;
		i2c_error <= 'd0;
		i2c_data_valid <= 'd0;
	end else begin
			case (pst)
				IDLE: begin 												//IDLE STATE 
					if(dv) begin 
						ir_wdata <= wdata;
						ir_addr <= addr;
						if (state_counter == 'd15) begin
							pst <= START; 
							out_sda <= 'd0;
						end  else pst <= IDLE;
					end else begin
						out_sda <= 'd1; 
						if (state_counter == 'd15)  pst <= IDLE;
					end
				end
				START: begin 												//START STATE
					if (state_counter == 'd15) begin
						pst <= ADDR; 
						out_sda <= addr[a_count-2];
					end else pst <= START;
				end
				ADDR: begin 												//ADDR STATE
					case (a_count)
						0: begin
							if (state_counter == 'd15) begin
								pst <= ASL_ACK; 
								out_sda <= 'd1;
							end  else pst <= ADDR;
						end
						1: begin
							if (state_counter == 'd15) begin
								out_sda <= ~write;
								pst <= ADDR;
							end  
						end
						default : begin
							if (state_counter == 'd15) begin
								pst <= ADDR;
								out_sda <= ir_addr[a_count-2];
							end  
						end
					endcase
				end
				ASL_ACK: begin 												//ASL_ACK STATE
					if (state_counter == 'd15 && in_sda) begin
							pst <= STOP;
							out_sda <= 'd0;
							i2c_error <= 'd1;
							i2c_ready <= 'd1;
					end else begin
						if (state_counter == 'd15) begin
							if (write) begin
								pst <= WDATA;
								out_sda <= ir_wdata[d_count];
							end else begin
								pst <= RDATA;
								out_sda <= 'd1;
							end	
						end else pst <= ASL_ACK;		
					end
				end
				WDATA: begin												//WDATA STATE		
					if (d_count == 0) begin
						if (state_counter == 'd15) begin
							pst <= DSL_ACK; 
							out_sda <= 'd1;
							i2c_ready <= 'd1;
						end else pst <= WDATA;	
					end else begin 
						if (state_counter == 'd15) begin
							pst <= WDATA;
							out_sda <= ir_wdata[d_count-1];
							i2c_ready <= 'd0;
						end
					end
				end
				DSL_ACK: begin 												//DSL_ACK STATE
					if (dv && (ir_addr == addr) && write) begin							
						ir_wdata <= wdata;
						if (state_counter == 'd15 && (~in_sda) ) begin
							pst <= WDATA;
							out_sda <= ir_wdata[d_count];
						end else if (state_counter == 'd15 && in_sda) begin
							pst <= STOP;
							out_sda <= 'd0;
							i2c_ready <= 'd1;
							i2c_error <= 'd1;
						end else begin
							pst <= DSL_ACK;
						end 								
					end else begin
						if (state_counter == 'd15) begin
							pst <= STOP;
							out_sda <= 'd0;
						end else pst <= DSL_ACK;	
					end
					i2c_ready <= 'd0;
				end
				RDATA: begin 												//RDATA STATE
						if (d_count == 0) begin
							if (state_counter == 'd15) begin
								pst <= DM_NACK;
								out_sda <= 'd0;
								i2c_ready <= 'd1;
							end else pst <= RDATA;

							if (state_counter == 'd9) begin
								ir_rdata[d_count] <= in_sda;
								i2c_data_valid <= 'd1;
							end
						end else begin
							if (state_counter == 'd15) begin
								pst <= RDATA;
								out_sda <= 'd1;
								i2c_ready <= 'd0; 
							end

							if (state_counter == 'd9) begin
								ir_rdata[d_count] <= in_sda; 	
							end 
						end
				end
				DM_NACK: begin 												//DM_NACK STATE
					i2c_data_valid <= 'd0;	
					if (dv && (ir_addr == addr) && (~write)) begin
						ir_wdata <= wdata;
						if (state_counter == 'd15) begin
							pst <= RDATA;
							out_sda <= 'd1;
						end else begin
							pst <= DM_NACK;
							out_sda <= 'd0;
						end 

					end else begin
						if (state_counter == 'd15) begin
							pst <= STOP;
							out_sda <= 'd0;
						end else if (state_counter == 'd6) begin
							out_sda <= 'd1;
							pst <= DM_NACK;
						end else pst <= DM_NACK;
					end
					i2c_ready <= 'd0;
				end
				STOP: begin 												//STOP STATE
					if (state_counter == 'd15) begin
						pst <= IDLE;
						out_sda <= 'd1;
					end else if (state_counter == 'd10) begin
						out_sda <= 'd1;
						pst <= STOP;
					end else begin
						pst <= STOP;
					end
					i2c_ready <= 'd0;
					i2c_error <= 'd0;
				end
				default: begin
					if (state_counter == 'd15)  pst <= IDLE;
					out_sda <= 'd1;
					i2c_ready <= 'd0;
				end
			endcase
	end
end
endmodule : i2c_trial