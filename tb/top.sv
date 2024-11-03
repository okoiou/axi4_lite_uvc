
`include "uvm_macros.svh"

module top;
    
    import uvm_pkg::*;
    import axi4_lite_pkg::*;
    import axi4_lite_env_pkg::*;
	import axi4_lite_test_pkg::*;

      
    bit system_clock, reset_n;
    
    // 25MHz clock freq for timescale 1ns
    parameter CLK_CYCLE = 20; 
    localparam delay_reset = 105;
    string logfile = "dump.vcd";
      
    initial begin
        system_clock =0;
        forever #(CLK_CYCLE) system_clock = ~system_clock;
    end 

    //reset initialization
    initial begin
        reset_n = 0;
        #delay_reset; //async reset
        reset_n = 1;
    end
    
    axi4_lite_if#(32,32)axi4_lite_vif (system_clock,reset_n);

    //interface
    initial begin
        uvm_config_db#(virtual axi4_lite_if#(32,32))::set(null,"*", "axi4_lite_vif", axi4_lite_vif);
    end
    
    // invoking simulation phases of all components
    initial begin
        run_test(""); 
    end
    // Waves
    initial begin
        $value$plusargs("DUMPNAME=%s", logfile);
        $dumpfile(logfile); 
        $dumpvars;
    end
endmodule 

