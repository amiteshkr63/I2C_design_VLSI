class apb_driver extends uvm_driver#(bridge_sequence_item);
	
	virtual bridge_interface.MP vif;
	virtual bridge_interface vif_main;

	bridge_sequence_item my_seq_item;

	`uvm_component_utils(apb_driver)

	function new(string name = "apb_driver", uvm_component parent = null);
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
		forever begin
			@(posedge vif.Pclk);
			if(vif.Presetn) begin
				my_seq_item = bridge_sequence_item::type_id::create("my_seq_item");
				seq_item_port.get_next_item(my_seq_item);
				wait(vif_main.Pready);
				vif.cb.Penable <= 'd0;
				if(my_seq_item.Pwrite) begin									//if write command then												//waiting for ready to be high 
					repeat(2)@(posedge vif.Pclk);
					vif.cb.Paddr <= my_seq_item.Paddr;
					vif.cb.Pwdata <= my_seq_item.Pwdata;
					vif.cb.Pwrite <= my_seq_item.Pwrite;
					vif.cb.Pselx <= my_seq_item.Pselx;
					@(posedge vif.Pclk)
					vif.cb.Penable <= my_seq_item.Penable;
					$display($time, "APB driver: Write Pack driven");
					my_seq_item.print();
					
				end else begin  									    //if read command then
					repeat(2)@(posedge vif.Pclk);
					vif.cb.Pselx <= my_seq_item.Pselx;		
					vif.cb.Pwrite <= my_seq_item.Pwrite;
					vif.cb.Paddr <= my_seq_item.Paddr;
					@(posedge vif.Pclk);
					vif.cb.Penable <= my_seq_item.Penable;
					$display($time, "APB driver: Read Pack driven");
					my_seq_item.print();
					
				end
				seq_item_port.item_done();
			end
		end
	endtask
endclass

