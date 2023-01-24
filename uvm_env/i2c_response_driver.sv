class i2c_response_driver extends uvm_driver#(bridge_sequence_item);
	
	virtual bridge_interface.MP vif;
	virtual bridge_interface vif_main;

	`uvm_component_utils(i2c_response_driver)

	function new(string name = "i2c_response_driver", uvm_component parent = null);
			super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual bridge_interface.MP)::get(this, "", "vif", vif )) begin
			`uvm_error(get_type_name(), "handle of interface unavailable")
		end
		if(!uvm_config_db#(virtual bridge_interface)::get(this, "", "vif_main", vif_main)) begin
			`uvm_error(get_type_name(), "handle of interface unavailable")
		end
	endfunction : build_phase

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
	endfunction : connect_phase

	virtual task run_phase(uvm_phase phase);
		logic [7:0] rdata;
		logic sig_read=0;
		forever begin
			@(posedge vif.Pclk);
			//wait(vif_main.Pready);
			if(vif.Presetn) begin
				if (vif_main.a_count == 0) begin
					//$display($time, "I2C rsp driver: after a_count wait");
					@(posedge vif.Pclk);
					@(posedge vif.cb.scl);
					@(negedge vif.cb.scl)
						vif_main.sda_flag <= 'd0;
					if(vif_main.Pwrite) begin									
						//$display($time, "I2C rsp driver: a0 inside if");
						@(negedge vif.cb.scl);
							vif_main.sda_flag <= 'd1;
						wait(vif_main.d_count == 0);
						repeat(3)@(posedge vif.Pclk);
						sig_read = 0;
					end else begin
						rdata = $random();
						//$display($time, "I2C rsp driver: a0 inside else %b", rdata);
						repeat(8)@(negedge vif.cb.scl) begin
							vif_main.sda_flag <= rdata[vif_main.d_count];							
						end
						//$display($time, "I2C rsp driver: data driven");
						sig_read = 1;
						//$display($time, "I2C rsp driver: a_count data driven, sig_read-1");

					end 
				end else if (vif_main.d_count == 0) begin
					//$display($time, "I2C rsp driver: after d_count wait");
					if (sig_read) begin
						//$display($time, "inside sig_read1");
						@(posedge vif.Pclk);
						@(posedge vif.cb.scl);
						@(negedge vif.cb.scl);
							vif_main.sda_flag <= 'd1;
						//$display($time, "inside sig_read1 after sda z");
						repeat(5)@(posedge vif.Pclk);
						if(~vif_main.Pwrite) begin									
							//$display($time, "I2C rsp driver: inside d0 inside if");
							rdata = $random();
							//$display($time, "I2C rsp driver:inside d0 inside else %b", rdata);
							repeat(8)@(negedge vif.cb.scl) begin
								vif_main.sda_flag <= rdata[vif_main.d_count];							
							end
							//$display($time, "I2C rsp driver: d_count data driven");	
							sig_read = 1;
							//$display($time, "I2C rsp driver: d_count data driven, sig_read-1");

						end 
					end else begin
						//$display($time, "inside sig_read0");
						@(negedge vif.cb.scl)
							vif_main.sda_flag <= 'd0;
						@(negedge vif.cb.scl);
							vif_main.sda_flag <= 'd1;
						//$display($time, "inside sig_read0 after sda z");
						if(vif_main.Pwrite) begin									//if write command then
							//$display($time, "I2C rsp driver: inside d0 inside if");
							wait(vif_main.d_count == 0);
							repeat(3)@(posedge vif.Pclk);
						end
					end
				end 										 								
			end
		end
	endtask
endclass

