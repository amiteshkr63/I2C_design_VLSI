typedef uvm_sequencer#(bridge_sequence_item) apb_sequencer;
class apb_agent extends uvm_agent;

	//apb_driver apb_driver;				//apb_driver handle
	apb_sequencer apb_sequencer_inst;			//apb_sequencer handle
	apb_monitorA apb_monitorA_inst;				//monitor handle
	apb_driver apb_driver_inst;
	uvm_analysis_port#(bridge_sequence_item) apb_agent2all;

	`uvm_component_utils(apb_agent)

	function new(string name = "apb_agent", uvm_component parent = null);				//constructor 
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		apb_driver_inst = apb_driver::type_id::create("apb_driver_inst", this);
		apb_sequencer_inst = apb_sequencer::type_id::create("apb_sequencer_inst", this);
		apb_monitorA_inst = apb_monitorA::type_id::create("apb_monitorA_inst", this);
		apb_agent2all = new("apb_agent2all", this);
	endfunction : build_phase

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		apb_driver_inst.seq_item_port.connect(apb_sequencer_inst.seq_item_export);   					//this required to connect to the apb_sequencer
		apb_monitorA_inst.apb_monitor2all.connect(apb_agent2all);												//connecting to analysis port of monitor, monitor outside----make changes.
	endfunction : connect_phase
	
endclass : apb_agent