module bridge_tb ();

	reg PCLK;				       	//clock						
	reg PRESETn;					//reset active low
	reg PWRITE;					//write/read control
	reg PSELx;					//select control from master
	reg PENABLE;					//control from master, Enable
	reg [6:0] PADDR;				//Address from master
	reg [7:0] PWDATA;				//write data from master

	wire [7:0] PRDATA;		//read data to master
	wire PREADY;				//ready signal to master
	wire PSLVERR;				//error signal to master

	wire scl;						//scl for i2c 
	wire sda;						//sda for i2c
	wire i2c_data_valid;			//data valid from i2c
	wire apb_data_valid;			//data valid to i2c
	wire [2:0] d_count;		//count for debug
	wire [3:0] a_count;		//count for debug

	pullup(sda);
	pullup(scl);

	reg t_pwrite=0;
	logic [7:0] rdata=0;
	logic sig_read=0;
	reg sda_flag = 1;
	assign sda = sda_flag?'dz:'d0;

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
			.apb_data_valid (apb_data_valid),
			.d_count        (d_count),
			.a_count        (a_count)
		);

	initial begin
		fork
			begin
				forever #5 PCLK = ~PCLK;
			end
			begin
			    PCLK = 0;
				PWDATA = 0;
				PADDR = 0;
				PSELx = 0;
				PENABLE = 0;
				PWRITE = 0;
				PRESETn = 0;
				#400;
				PRESETn = 1;
			end
			begin
				forever begin
					@(posedge PCLK);
					if(PRESETn) begin
						t_pwrite = $random();
						wait(PREADY);
						PENABLE = 'd0;
						if(t_pwrite) begin									//if write command then												//waiting for ready to be high 
							repeat(2)@(posedge PCLK);
							PADDR = 'h55;
							PWDATA = $random();
							PWRITE = 'd1;
							PSELx = 'd1;
							@(posedge PCLK)
							PENABLE	= 'd1;
							$display($time, "APB driver: Write Pack driven");
							repeat(10)@(posedge PCLK);
						end else begin  									    //if read command then
							repeat(2)@(posedge PCLK);
							PSELx = 'd1;		
							PWRITE = 'd0;
							PADDR <= 'h55;
							@(posedge PCLK);
							PENABLE <= 'd1;
							$display($time, "APB driver: Read Pack driven");
							repeat(10)@(posedge PCLK);			
						end
					end
				end
			end
			begin
				forever begin
					@(posedge PCLK);
					//wait(vif_main.Pready);
					if(PRESETn) begin
						if (a_count == 0) begin
							//$display($time, "I2C rsp driver: after a_count wait");
							@(posedge PCLK);
							@(posedge scl);
							@(negedge scl)
								sda_flag = 'd0;
							if(PWRITE) begin									
								//$display($time, "I2C rsp driver: a0 inside if");
								@(negedge scl);
									sda_flag = 'd1;
								wait(d_count == 0);
								repeat(3)@(posedge PCLK);
								sig_read = 0;
							end else begin
								rdata = $random();
								//$display($time, "I2C rsp driver: a0 inside else %b", rdata);
								repeat(8)@(negedge scl) begin
									repeat(2)@(posedge PCLK);
									sda_flag = rdata[d_count];							
								end
								//$display($time, "I2C rsp driver: data driven");
								sig_read = 1;
								//$display($time, "I2C rsp driver: a_count data driven, sig_read-1");

							end 
						end else if (d_count == 0) begin
							//$display($time, "I2C rsp driver: after d_count wait");
							if (sig_read) begin
								//$display($time, "inside sig_read1");
								@(posedge PCLK);
								@(posedge scl);
								@(negedge scl);
									sda_flag = 'd1;
								//$display($time, "inside sig_read1 after sda z");
								repeat(5)@(posedge PCLK);
								if(~PWRITE) begin									
									//$display($time, "I2C rsp driver: inside d0 inside if");
									rdata = $random();
									//$display($time, "I2C rsp driver:inside d0 inside else %b", rdata);
									repeat(8)@(negedge scl) begin
									    repeat(2)@(posedge PCLK);
										sda_flag = rdata[d_count];							
									end
									//$display($time, "I2C rsp driver: d_count data driven");	
									sig_read = 1;
									//$display($time, "I2C rsp driver: d_count data driven, sig_read-1");

								end 
							end else begin
								//$display($time, "inside sig_read0");
								@(negedge scl)
									sda_flag = 'd0;
								@(negedge scl);
									sda_flag = 'd1;
								//$display($time, "inside sig_read0 after sda z");
								if(PWRITE) begin									//if write command then
									//$display($time, "I2C rsp driver: inside d0 inside if");
									wait(d_count == 0);
									repeat(3)@(posedge PCLK);
								end
							end
						end 										 								
					end
				end
			end
		join
	end

endmodule : bridge_tb