/*
    Default configuration is one master and one slave agent for the test. You can set up environment cfg here.
*/
`include "uvm_macros.svh" 
class axi4_lite_base_test extends uvm_test;
    `uvm_component_utils(axi4_lite_base_test)

    axi4_lite_env_cfg cfg_env;
    axi4_lite_env env;
  	axi4_lite_cfg cfg;
    virtual axi4_lite_if#(32, 32)   axi4_lite_vif;

    extern function new(string name = "axi4_lite_base_test", uvm_component parent=null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void cfg_randomize(); 
    extern virtual function void start_of_simulation_phase(uvm_phase phase);
    extern virtual function void report_phase(uvm_phase phase);
    extern virtual function void set_default_configuration ();
    extern virtual function void set_configuration (); //Override this function to create different configuration
endclass 

//-------------------------------------------------------------------------------------------------------------
function  axi4_lite_base_test::new(string name = "axi4_lite_base_test", uvm_component parent=null);
	super.new(name,parent);
endfunction : new

//-------------------------------------------------------------------------------------------------------------
function void  axi4_lite_base_test::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual axi4_lite_if#(32, 32))::get(this, "", "axi4_lite_vif", axi4_lite_vif)) 
        `uvm_fatal("build_phase",{"virtual interface must be set for: ", get_full_name(),".axi4_lite_vif"});

    cfg_env = axi4_lite_env_cfg::type_id::create("cfg_env", this);
    env = axi4_lite_env::type_id::create("env", this);
    `uvm_info("build_phase", "Enviroment created.", UVM_HIGH)
    cfg = axi4_lite_cfg::type_id::create("cfg", this);
    cfg_randomize();
    set_configuration();
    
    uvm_config_db#(axi4_lite_env_cfg)::set(this,"env","cfg_env", cfg_env);
    uvm_config_db#(axi4_lite_cfg)::set(this, "*", "cfg", cfg);
endfunction : build_phase

//-------------------------------------------------------------------------------------------------------------
function void axi4_lite_base_test::cfg_randomize(); 
 	if (!cfg.randomize() with {
        //add constraints//

        })
    `uvm_fatal("build_phase","Configuration randomization failed");
endfunction : cfg_randomize

//-------------------------------------------------------------------------------------------------------------
function void axi4_lite_base_test::set_configuration();
    set_default_configuration();
endfunction

//-------------------------------------------------------------------------------------------------------------
function void axi4_lite_base_test::set_default_configuration ();
    cfg_env.has_master_agent = 1;
    cfg_env.has_slave_agent = 1;
    cfg_env.master_config.agent_type = MASTER;
    cfg_env.slave_config.agent_type = SLAVE;
    `uvm_info("config", "Default configuration set.", UVM_HIGH)
endfunction : set_default_configuration

//-------------------------------------------------------------------------------------------------------------
function void  axi4_lite_base_test::start_of_simulation_phase(uvm_phase phase);
	uvm_report_server svr;
    uvm_verbosity verbosity = UVM_LOW;

	super.start_of_simulation_phase(phase);
	uvm_top.set_timeout(.timeout(this.cfg.test_time_out), .overridable(1));
	`uvm_info("start_of_simulation_phase", $sformatf("Printing topology"), UVM_LOW)
	uvm_top.print_topology();
	svr = uvm_report_server::get_server();
    //set verbosity level for env
    $value$plusargs("VERBOSITY=%s", verbosity);
    `uvm_info("start_of_simulation_phase", $sformatf("Verbosity is set to %s.", verbosity.name()), UVM_LOW)
	env.set_report_verbosity_level_hier(verbosity);
	svr.set_max_quit_count(1000); //maximum number of errors 
endfunction

//-------------------------------------------------------------------------------------------------------------
function void  axi4_lite_base_test::report_phase(uvm_phase phase);
    uvm_report_server svr;
  	super.report_phase(phase);
  	svr = uvm_report_server::get_server();
endfunction







