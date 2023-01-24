class bridge_env extends uvm_env;

	`uvm_component_utils(bridge_env)						//factory registration

	apb_agent apb_agent_inst;
	i2c_agent i2c_agent_inst;
	bridge_scoreboard scoreboard;
	bridge_cov cov_inst;

	function new(string name = "bridge_env", uvm_component parent = null);				//constructor 
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		apb_agent_inst = apb_agent::type_id::create("apb_agent_inst", this);
		i2c_agent_inst = i2c_agent::type_id::create("i2c_agent_inst", this);
		scoreboard = bridge_scoreboard::type_id::create("scoreboard", this);
		cov_inst=bridge_cov::type_id::create("cov_inst", this);
		
	endfunction : build_phase

	function void connect_phase(uvm_phase phase);											//function
		super.connect_phase(phase);
		apb_agent_inst.apb_agent2all.connect(scoreboard.analysis_imp_before);
		i2c_agent_inst.i2c_agent2all.connect(scoreboard.analysis_imp_after);
		apb_agent_inst.apb_agent2all.connect(cov_inst.analysis_imp_before);
		i2c_agent_inst.i2c_agent2all.connect(cov_inst.analysis_imp_after);
	endfunction : connect_phase

endclass : bridge_env