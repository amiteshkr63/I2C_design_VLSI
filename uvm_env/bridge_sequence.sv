class bridge_sequence extends uvm_sequence#(bridge_sequence_item);
	rand bit sel_test;
	int no_of_pkts;


	bridge_sequence_item my_seq_item;

	`uvm_object_utils(bridge_sequence)

	function new(string name = "bridge_sequence");
		super.new(name);
		if (!$value$plusargs("no_of_pkts=%d",no_of_pkts)) begin
			no_of_pkts = 10;
		end
	endfunction : new

	virtual task body();
		repeat(no_of_pkts) begin
			my_seq_item = bridge_sequence_item::type_id::create("bridge_seq_item");

			start_item(my_seq_item);	
				if (sel_test) begin
					assert(my_seq_item.randomize() with {Pselx == 1; Penable == 0;});
				end	else begin
					assert(my_seq_item.randomize() with {Pselx == 1; Penable == 1; Paddr == 85;});
				end
			finish_item(my_seq_item);	
		end
	endtask : body

endclass : bridge_sequence

/*class bridge_sequence_kaddr extends bridge_sequence;
	`uvm_object_utils(bridge_sequence_kaddr)

	bit [`ADDR_WIDTH-1:0] written_addr [];
	virtual task body();
		my_seq_item = bridge_sequence_item::type_id::create("my_seq_item");
		start_item(my_seq_item);
			assert(my_seq_item.randomize() with {if (Pwrite) addr inside written_addr;  solve Pwrite before addr;});
			if(my_seq_item.Pwrite) begin
				written_addr = new[written_addr.size()+1](written_addr);
				written_addr[written_addr.size()-1]= my_seq_item.addr;
			end
		finish_item(my_seq_item);
	endtask : body
	
endclass*/


