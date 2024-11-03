//`ifndef axi4_lite_PKG_SV
//`define axi4_lite_PKG_SV

//------------------------------------------------------------------------------------------------------------
`include "uvm_macros.svh"
//`include "axi4_lite_if.sv"
package axi4_lite_pkg;
import uvm_pkg::*;
    `include "axi4_lite_defines.sv"
    `include "axi4_lite_cfg.sv"
    `include "axi4_lite_item.sv"
    `include "axi4_lite_coverage.sv"
    `include "axi4_lite_monitor.sv" 
    `include "axi4_lite_master_sequencer.sv"
    `include "axi4_lite_slave_sequencer.sv"
    `include "axi4_lite_master_sequence.sv"
    `include "axi4_lite_slave_sequence.sv"
    `include "axi4_lite_master_driver.sv"
    `include "axi4_lite_slave_driver.sv"
    `include "axi4_lite_agent.sv"
endpackage 

//`endif //axi4_lite_PKG_SV

