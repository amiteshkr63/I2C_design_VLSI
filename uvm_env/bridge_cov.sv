class bridge_cov extends bridge_scoreboard;
    //instances
    bridge_sequence_item prdata_queue_after[$];
    bridge_sequence_item pwdata_queue_after[$]; 
    bridge_sequence_item pwdata_item;
    bridge_sequence_item prdata_item;
    covergroup bridge_cg_din();
        data_in: coverpoint prdata_item.Prdata {
                bins data[8] = {[0:$]};
            }
    endgroup : bridge_cg_din

    covergroup bridge_cg_dout();
        data_out: coverpoint pwdata_item.Pwdata {
                bins data[8] = {[0:$]};
            }
    endgroup : bridge_cg_dout

    `uvm_component_utils(bridge_cov)

    function new(string name = "bridge_cov", uvm_component parent=null);
        super.new(name, parent);
        bridge_cg_din=new();
        bridge_cg_dout=new();
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase

    virtual function void connect_phase(uvm_phase phase);                                          
        super.connect_phase(phase);
    endfunction : connect_phase

    virtual function void write_before(bridge_sequence_item my_seq_item);
        if (~my_seq_item.Pwrite) begin
            prdata_queue_after.push_back(my_seq_item);
        end
    endfunction : write_before


    virtual function void write_after(bridge_sequence_item my_seq_item);
        if (my_seq_item.Pwrite) begin
            pwdata_queue_after.push_back(my_seq_item);
        end
    endfunction : write_after

    virtual task run_phase(uvm_phase phase);
        fork
            begin
                forever begin
                    wait((pwdata_queue_after.size() > 0) || (prdata_queue_after.size() > 0));
                    if (pwdata_queue_after.size() > 0)begin
                        pwdata_item = pwdata_queue_after.pop_front();
                        bridge_cg_dout.sample();
                    end
                    if (prdata_queue_after.size() > 0) begin
                        prdata_item = prdata_queue_after.pop_front();
                        bridge_cg_din.sample();
                    end     
                end
            end
        join
    endtask : run_phase

    virtual function void report_phase(uvm_phase phase);
       `uvm_info(get_type_name(), $sformatf("Coverage = %f%%", $get_coverage()), UVM_MEDIUM)
    endfunction : report_phase

endclass : bridge_cov
