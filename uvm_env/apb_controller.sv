module apb_controller (PCLK, PRESETn, PWRITE, PSELx, PENABLE, PADDR, PWDATA, PREADY, PSLVERR, PRDATA, i2c_ready, i2c_error, i2c_rdata, i2c_data_valid, i2c_addr, i2c_wdata,i2c_write,apb_data_valid);
	
	input PCLK, PRESETn; 									//input clock and reset

	//Inputs from master 
	input PWRITE, PSELx, PENABLE;  							//input control signals from master 
	input [6:0] PADDR;  									//input address from master for controller to be used by i2c
	input [7:0] PWDATA; 									//input data from master to write for controller to be used by i2c

	//output to master
	output reg [7:0] PRDATA; 								//output data from controller to be read by master
	output reg PREADY, PSLVERR; 							//tranfer of PREADY, PSLVERR to master 

	//input from slave
	input i2c_ready, i2c_error;          					//input response from i2c to transfer to master 
	input [7:0] i2c_rdata;  								//input of data from i2c to controller to be read by master
	input i2c_data_valid;									//input data valid from i2c for controller to read 

	//output to slave
	output reg [6:0] i2c_addr; 								//output addr from controller to i2c
	output reg [7:0] i2c_wdata; 							//output data from controller to write for i2c
	output reg i2c_write;                 					//output control signal to read and write from controller to i2c
	output reg apb_data_valid;								//output data valid to used by i2c

	//internal registers
	reg [6:0] ir_paddr;
	reg [7:0] ir_pwdata;


	typedef enum bit [1:0] {IDLE, SETUP, ACCESS} state; 		//enum for states of fsm

	state pst,nst;							           			//fsm pst(present state) and nst(next state)



	//sequential block for pst
	always_ff @(posedge PCLK , negedge PRESETn) begin
		if(~PRESETn) begin
			 	pst<=IDLE;
		end else begin
				pst<=nst;
		end
	end

	//PWDATA and PADDR registration in internal register
	always_ff @(posedge PCLK or negedge PRESETn) begin
		if(~PRESETn) begin
			ir_pwdata = 'd0;
			ir_paddr = 'd0;
		end else begin
			if (pst == SETUP) begin
				ir_pwdata = PWDATA;
				ir_paddr = PADDR;
			end
		end
	end

	//combinational block, nst determination
	always_comb begin
		case (pst)
			IDLE: begin
						case(PSELx)
							1'b1: nst= SETUP;
							default: nst= IDLE;
						endcase
				  end

			SETUP: begin
						case({PENABLE, PSELx})
							2'b11: nst= ACCESS;
							2'b01: nst= SETUP;
							default: nst= IDLE;
						endcase
				   end
			ACCESS: begin
						case({PENABLE, PSELx, i2c_ready})
							3'b111: nst= SETUP;
							3'b110: nst= ACCESS;
							3'b010: nst= SETUP;
							3'b011: nst= SETUP;
							default: nst= IDLE;
						endcase
				    end
			default: nst= IDLE;
		endcase
	
	end

	//output block 
	always_comb
		begin
			case(pst)	
				ACCESS:	begin
							if (PWRITE) begin
								 i2c_addr= ir_paddr;
								 i2c_wdata= ir_pwdata;
								 i2c_write=	'd1;
									apb_data_valid= 'd1;

								 PRDATA= 'd0;
								 PSLVERR= i2c_error;
								 PREADY= i2c_ready;
							end else begin
								i2c_addr= ir_paddr;
								i2c_wdata= 'd0;
								i2c_write= 'd0;
								apb_data_valid=	'd1;
								if (i2c_data_valid) begin
									PRDATA= i2c_rdata;
									PREADY= i2c_ready;
									PSLVERR= i2c_error;
								end else begin
									PRDATA=	'd0;
									PREADY= i2c_ready;
									PSLVERR= i2c_error;
								end
							end
				end

				SETUP: 	begin
							i2c_addr= 'd0;
							i2c_wdata= 'd0;
							i2c_write=	'd0;
							apb_data_valid= 'd0;
							PRDATA= 'd0;
							PSLVERR= 'd0;
							PREADY= 'd1;
				end

				IDLE:	begin
							i2c_addr= 'd0;
							i2c_wdata= 'd0;
							i2c_write=	'd0;
							apb_data_valid= 'd0;
							PRDATA= 'd0;
							PSLVERR= 'd0;
							PREADY= 'd1;
				end

				default: begin
							i2c_addr= 'd0;
							i2c_wdata= 'd0;
							i2c_write=	'd0;
							apb_data_valid= 'd0;
							PRDATA= 'd0;
							PSLVERR= 'd0 ;
							PREADY= 'd0;
				end
			endcase
		end

endmodule









