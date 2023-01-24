module apb_i2c_bridge_tb ();

	reg PCLK;
	reg PRESETn;
	reg PWRITE;
	reg PSELx;
	reg PENABLE;
	reg [6:0] PADDR;
	reg [7:0] PWDATA;
	reg [7:0] PRDATA;

	wire PREADY;
	wire PSLVERR;
	wire scl;
	wire sda;
	
	pullup (scl);
	pullup (sda);

	wire [2:0] d_count;
	wire [3:0] a_count;

	reg [5:0] count=0;
	reg [5:0] readcount=0;
	reg [3:0] state_count_tb;
	reg [2:0] scl_count_tb;
	reg sda_flag = 1;
	int i=33;

	reg [7:0] rdata = 'hAA;

	apb_i2c_bridge inst_apb_i2c_bridge
		(
			.PCLK           (PCLK),
			.PRESETn        (PRESETn),
			.PWRITE         (PWRITE),
			.PSELx          (PSELx),
			.PENABLE        (PENABLE),
			.PADDR          (PADDR),
			.PWDATA         (PWDATA),
			.PRDATA         (PRDATA),
			.PREADY         (PREADY),
			.PSLVERR        (PSLVERR),
			.scl            (scl),
			.sda            (sda),
			.i2c_data_valid (i2c_data_valid),
			.d_count        (d_count),
			.a_count        (a_count)
		);







	asyncLowR inst_asyncLowR1 (.aRLowIn(PRESETn), .Clk(PCLK), .aLsyncResetOut(aLsyncResetOut));




	task apb_idle;
		begin
			PWRITE=0;
			PSELx=0;
			PENABLE=0;
			PADDR=0;
			PWDATA=0;
		end
	endtask

	task apb_write;
		input [6:0] addr_tk;
		input [7:0] data_tk;
		begin
			PWRITE=1;
			PSELx=1;
			PADDR=addr_tk;
			PWDATA=data_tk;
			@(posedge PCLK);
				PENABLE=1;
		end
	endtask

	task apb_read;
		input [6:0] addr_tk;
		begin
			PWRITE=0;
			PSELx=1;
			PADDR=addr_tk;
			
			@(posedge PCLK);
				PENABLE=1;
			PWDATA='hz;
		end
		
	endtask

	initial begin
		fork
			begin
				PCLK=0;
				PRESETn=0;
				#200;
				PRESETn=1;				
			end
			begin
				forever begin
						if (PRESETn) begin
							@(posedge PCLK);
							if (readcount == 54) begin
								if(state_count_tb == 15) readcount = 0;
							end else if (readcount == 0) begin
								wait(~scl);
								if (state_count_tb == 0) begin
									readcount= readcount +1;
								end
							end else begin
								if (state_count_tb == 15) begin
									readcount = readcount + 1;
									if(~PWRITE && readcount>40 && readcount <48) begin
										i=i+2;
									end	
								end
							end
						end else begin
							@(posedge PCLK);
						end
				end
			end
			begin
				forever begin
					if (PRESETn) begin
						@(posedge PCLK);
						if (count == 54) begin
							if(scl_count_tb == 7) count = 0;
						end else if (count == 0) begin
							wait (~scl);
							if (scl_count_tb == 7) begin
								count= count +1;
							end
						end else begin
							if (scl_count_tb == 7) begin
								count = count + 1;
							end
						end
						if(PWRITE) begin
							if (count == 16 || count ==17 || count == 34 || count == 35) begin
								sda_flag = 0;
							end else sda_flag = 1;
						end else begin
							if (count == 16 || count ==17) begin
								sda_flag = 0;
							end else if(readcount>39 && readcount <48) begin
								sda_flag = rdata[readcount-i];
							end else begin
								sda_flag = 1;
							end 
						end	
					end else begin
						@(posedge PCLK);
					end
				end	
			end
		join
	end

	

	initial begin
			begin
				apb_idle();
				#400
				apb_write('h55,'hAA);
				repeat(304) @(posedge PCLK);
				apb_idle();
				@(posedge PCLK);
				apb_write('h55,'h55);
				repeat(144) @(posedge PCLK);
				apb_idle();
				@(posedge PCLK);
				apb_read('h55);
			end
	end
		
	assign sda=sda_flag?'dz:'d0;

	always
		begin
			#5 PCLK=~PCLK;
		end

	always @(posedge PCLK) begin
		if (~aLsyncResetOut) begin
			scl_count_tb = 0;
			state_count_tb = 0;
		end else begin
			scl_count_tb = scl_count_tb + 1;
			state_count_tb= state_count_tb +1;
		end
	end

	
endmodule : apb_i2c_bridge_tb

