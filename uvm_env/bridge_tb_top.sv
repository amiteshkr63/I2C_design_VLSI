module bridge_tb_top();
	import bridge_pkg::*;
	import uvm_pkg::*;
	
	
	bit Pclk;

	bridge_interface intf(Pclk);						//do the necessary changes
	
	pullup(intf.sda);
	pullup(intf.scl);

	apb_i2c_bridge inst_apb_i2c_bridge
		(
			.PCLK           (Pclk),
			.PRESETn        (intf.Presetn),
			.PWRITE         (intf.Pwrite),
			.PSELx          (intf.Pselx),
			.PENABLE        (intf.Penable),
			.PADDR          (intf.Paddr),
			.PWDATA         (intf.Pwdata),
			.PRDATA         (intf.Prdata),
			.PREADY         (intf.Pready),
			.PSLVERR        (intf.Pslverr),
			.scl            (intf.scl),
			.sda            (intf.sda),
			.i2c_data_valid (intf.i2c_data_valid),
			.apb_data_valid(intf.apb_data_valid),
			.d_count        (intf.d_count),
			.a_count        (intf.a_count)
		);


	initial begin
		intf.Pwdata = 0;
		intf.Paddr = 0;
		intf.Pselx = 0;
		intf.Penable = 0;
		intf.Pwrite = 0;
		intf.Presetn = 0;
		#400;
		intf.Presetn = 1;
	end

	initial begin
		uvm_config_db#(virtual bridge_interface.MP)::set(null, "*", "vif", intf ); 
		uvm_config_db#(virtual bridge_interface.IP)::set(null, "*", "vif_IN", intf ); 
		uvm_config_db#(virtual bridge_interface)::set(null, "*", "vif_main", intf ); 
		
		run_test("bridge_test");
	end

	initial begin
		forever #5 Pclk = ~Pclk;
	end

	




endmodule : bridge_tb_top