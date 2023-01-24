`uvm_analysis_imp_decl(_before)
`uvm_analysis_imp_decl(_after)
class bridge_scoreboard extends uvm_scoreboard;
	int correct;
	`uvm_component_utils(bridge_scoreboard)								//factory registration
	bridge_sequence_item pwdata_queue_before[$];						//queue to store driven data
	bridge_sequence_item pwdata_queue_after[$];						//queue to store driven data
	bridge_sequence_item prdata_queue_before[$];
	bridge_sequence_item prdata_queue_after[$];


	uvm_analysis_imp_before#(bridge_sequence_item, bridge_scoreboard) analysis_imp_before; 
	uvm_analysis_imp_after#(bridge_sequence_item, bridge_scoreboard) analysis_imp_after;	

	//reg [`DATA_WIDTH-1:0] shadow_mem [`DEPTH-1:0];	

	function new(string name = "bridge_scoreboard", uvm_component parent = null );
		super.new(name, parent);
		/*for (int i = 0; i < `DEPTH; i++) begin
			shadow_mem[i] = `RESET_VALUE;
		end*/
		correct =0;
	endfunction : new

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		analysis_imp_before = new("analysis_imp_before", this);
		analysis_imp_after = new("analysis_imp_after", this);
	endfunction : build_phase

	virtual function void connect_phase(uvm_phase phase);											//function
		super.connect_phase(phase);
	endfunction : connect_phase

	virtual function void write_before(bridge_sequence_item my_seq_item);
		if (my_seq_item.Pwrite) begin
			pwdata_queue_before.push_back(my_seq_item);
		end else begin
			prdata_queue_after.push_back(my_seq_item);
		end
	endfunction : write_before


	virtual function void write_after(bridge_sequence_item my_seq_item);
		if (my_seq_item.Pwrite) begin
			pwdata_queue_after.push_back(my_seq_item);
		end else begin
			prdata_queue_before.push_back(my_seq_item);
		end	
	endfunction : write_after

	virtual task run_phase(uvm_phase phase);
		bridge_sequence_item pwdata_item;
		bridge_sequence_item prdata_item;
		bridge_sequence_item expected_pwdata;
		bridge_sequence_item expected_prdata;
		fork
			begin
				forever begin
					wait(((pwdata_queue_before.size() > 0 ) && (pwdata_queue_after.size() > 0)) || ((prdata_queue_before.size() > 0) && (prdata_queue_after.size() > 0)));
					if ((pwdata_queue_before.size() > 0 ) && (pwdata_queue_after.size() > 0)) begin
						expected_pwdata = pwdata_queue_before.pop_front();
						pwdata_item = pwdata_queue_after.pop_front();
						if(expected_pwdata.Pwdata == pwdata_item.Pwdata) begin
							pwdata_item.print();
							expected_pwdata.print();
							`uvm_info(get_type_name(), "Operation Correct", UVM_MEDIUM)
							correct++;
						end else begin
							pwdata_item.print();
							expected_pwdata.print();
							`uvm_error (get_type_name(), "Operation Incorrect")
						end
					end
					if ((prdata_queue_before.size() > 0) && (prdata_queue_after.size() > 0)) begin
						expected_prdata = prdata_queue_before.pop_front();
						prdata_item = prdata_queue_after.pop_front();
						if (expected_prdata.Prdata == prdata_item.Prdata) begin
						 	prdata_item.print();
						 	expected_prdata.print();
						 	`uvm_info(get_type_name(), "Operation Correct", UVM_MEDIUM)
						 	correct++;
						end else begin
							prdata_item.print();
							expected_prdata.print();
							`uvm_error (get_type_name(), "Operation Incorrect")
						end	
					end 	
				end
			end
		join
	endtask : run_phase

	virtual function void report_phase(uvm_phase phase);
		`uvm_info(get_type_name(),$sformatf("Total correct results: %0d",correct), UVM_MEDIUM)
	endfunction : report_phase

endclass : bridge_scoreboard