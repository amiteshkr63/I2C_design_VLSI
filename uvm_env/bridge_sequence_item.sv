class bridge_sequence_item extends uvm_sequence_item;
	//inputs
	rand bit Pselx;
	rand bit Pwrite;
	rand bit Penable;	
	rand bit [`ADDR_WIDTH-1:0] Paddr;
	rand bit [`DATA_WIDTH-1:0] Pwdata;

	//outputs
	bit Pready;
	bit Pslverr;
	bit [`DATA_WIDTH-1:0] Prdata;
	bit scl;
	bit sda;

	`uvm_object_utils_begin(bridge_sequence_item)
		`uvm_field_int(Pselx, UVM_DEFAULT)
		`uvm_field_int(Pwrite, UVM_DEFAULT)
		`uvm_field_int(Penable, UVM_DEFAULT)
		`uvm_field_int(Paddr, UVM_DEFAULT)
		`uvm_field_int(Pwdata, UVM_DEFAULT)
		`uvm_field_int(Pready, UVM_DEFAULT)
		`uvm_field_int(Pslverr, UVM_DEFAULT)
		`uvm_field_int(Prdata, UVM_DEFAULT)
		`uvm_field_int(scl, UVM_DEFAULT)
		`uvm_field_int(sda, UVM_DEFAULT)
	`uvm_object_utils_end

	function new(string name = "bridge_sequence_item");
		super.new(name);
	endfunction : new

endclass // bridge_sequence_item
