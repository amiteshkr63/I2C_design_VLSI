class i2c_monitorA extends uvm_monitor;
	
	virtual bridge_interface.IP vif;

	bridge_sequence_item my_seq_item;

	`uvm_component_utils(i2c_monitorA)

	uvm_analysis_port#(bridge_sequence_item) i2c_monitor2all;

	function new(string name = "i2c_monitorA", uvm_component parent = null);			//constructor
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);											//build phase
		super.build_phase(phase);
		if(!uvm_config_db#(virtual bridge_interface.IP)::get(this, "", "vif_IN", vif )) begin
			`uvm_error(get_type_name(), "handle of interface unavailable")
		end
		i2c_monitor2all = new("i2c_monitor2all", this);
	endfunction : build_phase

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
	endfunction : connect_phase

	virtual task run_phase(uvm_phase phase);											//run phase
		logic [7:0] temp_pwdata;
		logic [7:0] temp_prdata;
		logic sig_write=1;
		forever begin
			@(posedge vif.Pclk);
			if(vif.Presetn) begin
				if(sig_write ^ vif.cb_mon.Pwrite) begin 
					wait ((vif.cb_mon.a_count == 0) || (vif.cb_mon.d_count == 0));
					//$display($time, "I2C Monitor: waited", sig_write);
					if(vif.cb_mon.Pwrite) begin	
						my_seq_item = bridge_sequence_item::type_id::create("my_seq_item");
							repeat(2)@(negedge vif.cb_mon.scl);
							repeat(8) begin
								@(posedge vif.cb_mon.scl) temp_pwdata[vif.cb_mon.d_count] = vif.cb_mon.sda;
							end
							my_seq_item.Pwrite = 'd1;
							my_seq_item.Pwdata = temp_pwdata;
							//$display($time, "I2C Monitor: Write Pack DATA");
						my_seq_item.print();
						i2c_monitor2all.write(my_seq_item);	
						sig_write = 1;
						//$display($time, "I2C Monitor: sent to ap, sig_write= %d", sig_write);			
					end else begin
						my_seq_item = bridge_sequence_item::type_id::create("my_seq_item");
						//wait ((vif.cb_mon.a_count == 0) || (vif.cb_mon.d_count == 0));
							repeat(2)@(negedge vif.cb.scl);
							//$display($time, "I2C Monitor: after negedge");
							repeat(8) begin
								@(posedge vif.cb_mon.scl) temp_prdata[vif.cb_mon.d_count] = vif.cb_mon.sda;
							end
							my_seq_item.Pwrite = 'd0;
							my_seq_item.Prdata = temp_prdata;
							//$display($time, "I2C Monitor: Read Pack DATA");
						my_seq_item.print();
						i2c_monitor2all.write(my_seq_item);
						sig_write = 0;
						//$display($time, "I2C Monitor: sent to ap, sig_write= %d", sig_write);
					end	
				end else begin
					//$display($time, "I2C Monitor: didn't wait", sig_write);
					if(vif.cb_mon.Pwrite) begin	
						my_seq_item = bridge_sequence_item::type_id::create("my_seq_item");
							@(negedge vif.cb_mon.scl);
							repeat(8) begin
								@(posedge vif.cb_mon.scl) temp_pwdata[vif.cb_mon.d_count] = vif.cb_mon.sda;
							end
							my_seq_item.Pwrite = 'd1;
							my_seq_item.Pwdata = temp_pwdata;
							//$display($time, "I2C Monitor: Write Pack DATA");
						my_seq_item.print();
						i2c_monitor2all.write(my_seq_item);	
						sig_write = 1;
						//$display($time, "I2C Monitor: sent to ap, sig_write= %d", sig_write);			
					end else begin
						my_seq_item = bridge_sequence_item::type_id::create("my_seq_item");
						//wait ((vif.cb_mon.a_count == 0) || (vif.cb_mon.d_count == 0));
							repeat(1)@(negedge vif.cb.scl);
							//$display($time, "I2C Monitor: after negedge in no wait");
							repeat(8) begin
								@(posedge vif.cb_mon.scl) temp_prdata[vif.cb_mon.d_count] = vif.cb_mon.sda;
							end
							my_seq_item.Pwrite = 'd0;
							my_seq_item.Prdata = temp_prdata;
							//$display($time, "I2C Monitor: Read Pack DATA");
						my_seq_item.print();
						i2c_monitor2all.write(my_seq_item);
						sig_write = 0;
						//$display($time, "I2C Monitor: sent to ap, sig_write= %d", sig_write);
					end	
				end																					
			end 
			wait(vif.cb_mon.Pready);
			repeat(7)@(posedge vif.Pclk);
		end
	endtask : run_phase 

endclass : i2c_monitorA