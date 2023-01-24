class bridge_test extends uvm_test;
	`uvm_component_utils(bridge_test)

	bridge_env env;

	function new(string name = "bridge_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env = bridge_env::type_id::create("env", this);
	endfunction : build_phase

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
	endfunction : connect_phase

	virtual task run_phase(uvm_phase phase);
		bridge_sequence seq;
		phase.raise_objection(this);
			seq = bridge_sequence::type_id::create("seq");
			assert(seq.randomize() with {sel_test == 0;});		 						//does the randomization part only in sequence class
			seq.start(env.apb_agent_inst.apb_sequencer_inst);					//creates the handshake mechanism btwn driver and sequencer
			phase.phase_done.set_drain_time(this, 3600);
		phase.drop_objection(this);						//run_phase ends here
	endtask : run_phase
endclass : bridge_test