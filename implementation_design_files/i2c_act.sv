//POST_SYNTHESIS
module i2c_actuator(
	input clk,    // Clock
	input rst_n,
	input [6:0]i_taaddr6_0,		//From APB addr getting target addr and mmaddr location to write wdata
	input in_sda,
	input [7:0]i_wdata,							//One Block Write
	input i_apb_dv_n,
	input i_write_n,
	output o_scl,
	output reg out_sda,
	output reg o_i2c_err,
	output reg [9:0]state_count,
	output reg [2:0]ta_count,
	output reg [2:0]d_count,
	output reg ta_count_done,
	output reg d_count_done,
	output reg state_count_done,
	output reg o_act_stop_idle_flag,
	output reg or_act_rdbsybar
);

enum /*bit[2:0]*/{IDLE, START, TADDR, TASL_ACK, WDATA, DSL_ACK, STOP}act_pst;/////////

//Internal Signals
reg [7:0]ir_wdata;
reg [7:0]ir_trgtaddr;

//Counters
reg state_scl_done;

//reg dual_clk;
/***************************************STATUS COUNT LOGIC STARTS*************************************/		
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		state_count <= 0;
		state_count_done<=0;
		state_scl_done<=0;
	end else begin
		if ((state_count==999) || (act_pst==IDLE)) begin
			state_count=0;
			state_scl_done<=0;
		end
		else state_count <= state_count + 1;
		//state scl done signal
		case (state_count)
/*			1:		if(!((act_pst==START) || (ta_count==0))) begin
						state_scl_done<='d1;
						state_count_done<='d0;
					end*/
			0:		begin
						state_scl_done <= 'd0;
						state_count_done <= 'd0;
					end
			499:	begin
						state_scl_done<='d1;
						state_count_done <= 'd0;
					end
			998: 	begin
						if(!((act_pst==START) || (act_pst==STOP)/*|| (ta_count==0)*/))  state_scl_done<='d1; 
						state_count_done <= 'd1;
					end		
			default : 
				begin
					state_scl_done <= 'd0;
					state_count_done <= 'd0;
				end
		endcase
	end
end
/***************************************STATUS COUNT LOGIC ENDS***************************************/

/********************************SCL LOGIC START***************************************************/
reg scl_en=0;
assign o_scl=scl_en?'d0:'dz;
//scl enable
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		scl_en <= 'd0;
	end else begin
		if (act_pst==IDLE) begin
			scl_en='d0;
		end
		if (state_scl_done) begin
			scl_en=~scl_en;
		end
	end
end
/********************************SCL LOGIC END******************************************************/
//Counters
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		ta_count <= 0;
		d_count <= 0;
		d_count_done <= 0;
		ta_count_done <= 0;
	end else begin
		case(act_pst) 
			//counter for TADDR state
			TADDR:
			begin
				//address state done signal
				case (ta_count)
					7: 	begin
							if (state_count==998) begin
								ta_count_done <= 'd1;
							end
						end
					default : begin
								ta_count_done <= 'd0;
							  end
				endcase 
				if (state_count_done)	ta_count <= ta_count + 1;
				else ta_count<=ta_count;
			end
/*			TASL_ACK: 
			begin
				ta_count<=0;
				ta_count_done<=0;
			end*/
			//counter for WDATA state
			WDATA:
			begin
				case (d_count)
					7: 	begin 
							if (state_count==998) begin
								d_count_done <= 'd1;
							end
						end		
					default : d_count_done <= 'd0;
				endcase 
					if(state_count_done)	d_count <= d_count + 1;
					else	d_count<=d_count;
			end
/*			DSL_ACK:
			begin
				d_count<=0;
				d_count_done=0;/////////////////////
				//total bytes count done
			end*/
			//Initialization
			default:
				begin
					ta_count <= 0;
					d_count <= 0;
					d_count_done <= 0;
					ta_count_done <= 0;
				end
		endcase
	end
end

//state machine and out_sda hanling
always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n) begin
		/////////////////////////////
		/**/ir_wdata<=0;   		   //
		/**/ir_trgtaddr<=0;		   //
		/**/o_i2c_err<=0;	  	   //
		/**/out_sda<='d1;		   //
		/**/or_act_rdbsybar<='d0;//
		/**/act_pst <= IDLE;	   //
		/**/o_act_stop_idle_flag=0; //
		////////////////////////////
	end else begin
		case (act_pst)
		 	IDLE:
		 		begin
			 		ir_trgtaddr[7:0]<={i_taaddr6_0, i_write_n};
		 			if ((~i_apb_dv_n) && (~i_write_n)) begin
			 			ir_wdata<=i_wdata;
						o_i2c_err<=0;
			 			out_sda<=0;
						or_act_rdbsybar<=0;
			 			act_pst<=START;
			 			o_act_stop_idle_flag=0;
		 			end
		 			else begin
		 				/////////////////////////////
		 				/**/ir_wdata<=0;   		   //
		 				/**/ir_trgtaddr<=0;		   //
		 				/**/o_i2c_err<=0;	  	   //
		 				/**/out_sda<='d1;		   //
		 				/**/or_act_rdbsybar<='d0;  //
		 				/**/act_pst <= IDLE;	   //
		 				/**/o_act_stop_idle_flag=0;//
		 				////////////////////////////
		 			end
		 		end
		 	START:
		 		begin
		 			o_act_stop_idle_flag=0;
		 			if (state_count_done) begin
		 				out_sda<=ir_trgtaddr[7];
		 				act_pst<=TADDR;
		 			end
		 		end
		 	TADDR:
		 		begin
		 			if (ta_count_done && state_count_done) begin
		 				out_sda<='d1;//////////////
		 				act_pst<=TASL_ACK;
		 			end
		 			else begin
		 				if(state_count_done)	out_sda<=ir_trgtaddr[6 - ta_count];
		 				act_pst<=TADDR;
		 			end
		 		end
		 	TASL_ACK:
		 		begin
		 			if ((in_sda) && (state_scl_done)) begin
		 				o_i2c_err<=1;/**/
		 				act_pst<=TASL_ACK;
		 			end
	 				if (state_count_done) begin
	 					if (o_i2c_err) begin
 							out_sda<='d0;
 							act_pst<=STOP;
	 					end
	 					else begin
		 					out_sda <= ir_wdata[7];
		 					act_pst <= WDATA; 						
	 					end	
	 				end
	 				else begin
	 					out_sda<='d1;//////////////
	 					act_pst<=TASL_ACK;
	 				end
		 		end
		 	WDATA:
		 		begin
		 			if (d_count_done && state_count_done) begin
		 				out_sda<='d1;
						or_act_rdbsybar<='d1;
		 				act_pst<=DSL_ACK;
		 			end
		 			else begin
		 				//out_sda<=ir_wdata[6 - d_count];
		 				out_sda<=ir_wdata[7 - d_count];
						or_act_rdbsybar<='d0;
		 				act_pst<=WDATA;
		 			end
		 		end
		 	DSL_ACK:
		 		begin
		 			or_act_rdbsybar<='d0;
		 			if ((in_sda) && (state_scl_done)) begin
		 				o_i2c_err<=1;
		 				act_pst<=DSL_ACK;
		 			end
	 				if (state_count_done) begin
	 					if (o_i2c_err) begin
	 						out_sda<='d0;
	 						act_pst<= STOP;
	 					end	
	 					else if((ir_trgtaddr[7:1]==i_taaddr6_0) && (~i_write_n) && (~i_apb_dv_n)) begin
	 						out_sda <= ir_wdata[7];
	 						act_pst <= WDATA;		
	 					end
	 					else begin
	 						out_sda<='d0;
	 						act_pst<= STOP;
	 					end
	 				end
	 				else begin
	 					out_sda<='d1;
	 					act_pst<=DSL_ACK;
	 				end
		 		end
		 	STOP:
		 		begin
					if (state_count_done) begin
						o_act_stop_idle_flag=1;
						out_sda <= 'd1;
						act_pst <= IDLE;
					end else begin
						if(state_count==750)	out_sda <= 'd1;
						act_pst <= STOP;
					end
		 		end
		 	 default:
			  	begin
			  		///////////////////////////
			  		/**/ir_wdata<=0;   		 //
			  		/**/ir_trgtaddr<=0;		 //
			  		/**/o_i2c_err<=0;	  	 //
			  		/**/out_sda<='d1;		 //
				 	/**/or_act_rdbsybar<=0;	 //
			  		/**/act_pst <= IDLE;	 //
			  		///////////////////////////
			  	end
		endcase
	end
end
endmodule : i2c_actuator