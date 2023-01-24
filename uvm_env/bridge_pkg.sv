`define UVM_NO_DPI
`include "uvm_pkg.sv"
package bridge_pkg;
	import uvm_pkg::*;

	`include "uvm_macros.svh"
	`include "bridge_defines.svh"
	`include "bridge_sequence_item.sv"
	`include "bridge_sequence.sv"
	`include "apb_driver.sv"
	`include "i2c_response_driver.sv"
	`include "apb_monitorA.sv"
	`include "i2c_monitorA.sv"
	`include "bridge_scoreboard.sv"
	`include "bridge_cov.sv"
	`include "apb_agent.sv"
	`include "i2c_agent.sv"
	`include "bridge_env.sv"
	`include "bridge_test.sv"
	

	
endpackage : bridge_pkg