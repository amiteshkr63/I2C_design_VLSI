class apb_monitorA extends uvm_monitor;
	
	virtual bridge_interface.IP vif;

	bridge_sequence_item my_seq_item;

	`uvm_component_utils(apb_monitorA)

	uvm_analysis_port#(bridge_sequence_item) apb_monitor2all;

	function new(string name = "apb_monitorA", uvm_component parent = null);			//constructor
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);											//build phase
		super.build_phase(phase);
		if(!uvm_config_db#(virtual bridge_interface.IP)::get(this, "", "vif_IN", vif )) begin
			`uvm_error(get_type_name(), "handle of interface unavailable")
		end
		apb_monitor2all = new("apb_monitor2all", this);
	endfunction : build_phase

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
	endfunction : connect_phase

	virtual task run_phase(uvm_phase phase);											//run phase
		forever begin
			@(posedge vif.Pclk);
			if(vif.Presetn) begin
				//$display($time, "APB Monitor: before wait");
				wait(vif.cb_mon.Pready);
				//$display($time, "APB Monitor: after wait");
				repeat(5)@(posedge vif.Pclk);														
				if(vif.cb_mon.Pwrite) begin
					my_seq_item = bridge_sequence_item::type_id::create("my_seq_item");
					wait(vif.cb_mon.apb_data_valid);
					my_seq_item.Paddr = vif.cb_mon.Paddr;
					my_seq_item.Pwdata = vif.cb_mon.Pwdata;
					my_seq_item.Pwrite = 'd1;
					//$display($time, "APB Monitor: Write Pack DATA");
					my_seq_item.print();
					apb_monitor2all.write(my_seq_item);
				end else begin
					my_seq_item = bridge_sequence_item::type_id::create("my_seq_item");
					wait(vif.cb_mon.apb_data_valid);
					my_seq_item.Paddr = vif.cb_mon.Paddr;
					my_seq_item.Pwrite = 'd0;
					wait(vif.cb_mon.i2c_data_valid);
					my_seq_item.Prdata = vif.cb_mon.Prdata;
					//$display($time, "APB Monitor: Read Pack DATA");
					my_seq_item.print();
					apb_monitor2all.write(my_seq_item);
				end
			end
			
		end
	endtask : run_phase 

endclass : apb_monitorA
