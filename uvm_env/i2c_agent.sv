class i2c_agent extends uvm_agent;

	i2c_response_driver i2c_rsp_driver;				//i2c_rsp_driver handle
	i2c_monitorA i2c_monitorA_inst;				//monitor handle
	uvm_analysis_port#(bridge_sequence_item) i2c_agent2all;

	`uvm_component_utils(i2c_agent)

	function new(string name = "i2c_agent", uvm_component parent = null);				//constructor 
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		i2c_rsp_driver = i2c_response_driver::type_id::create("i2c_rsp_driver", this);
		i2c_monitorA_inst = i2c_monitorA::type_id::create("i2c_monitorA", this);
		i2c_agent2all = new("i2c_agent2all", this);
	endfunction : build_phase

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		//i2c_rsp_driver.seq_item_port.connect(i2c_sequencer.seq_item_export);   					//this required to connect to the i2c_sequencer
		i2c_monitorA_inst.i2c_monitor2all.connect(i2c_agent2all);												//connecting to analysis port of monitor, monitor outside----make changes.
	endfunction : connect_phase
	
endclass : i2c_agent