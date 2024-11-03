/*
Environment class, by default creates two agents and scoreboard.
One agent is configured as Master, other as Slave.
Both agent's monitors are connected to Scoreboards through Analysis ports.
Feel free to adapt ENV to meet your specific needs.
*/


class axi4_lite_env extends uvm_env;

    `uvm_component_param_utils(axi4_lite_env)

    axi4_lite_env_cfg cfg_env;
    axi4_lite_agent#(32,32) master_agent;
    axi4_lite_agent#(32,32) slave_agent;
    axi4_lite_sb sb; 

    extern function new (string name, uvm_component parent);
    extern virtual function void build_phase (uvm_phase phase);
    extern virtual function void connect_phase (uvm_phase phase);
    extern virtual function void print_cfg();
endclass : axi4_lite_env

function axi4_lite_env :: new (string name, uvm_component parent);
    super.new(name, parent);
endfunction : new

function void axi4_lite_env:: build_phase (uvm_phase phase);
    super.build_phase(phase);
    
    if (!uvm_config_db # (axi4_lite_env_cfg) :: get (this, "", "cfg_env", cfg_env)) begin
        `uvm_fatal (get_type_name(), "Failed to get the configuration file from the config DB!")
    end 
    
    master_agent = axi4_lite_agent#(32,32) :: type_id :: create ("master_agent", this);
    slave_agent = axi4_lite_agent#(32,32) :: type_id :: create ("slave_agent", this);

    master_agent.cfg = cfg_env.master_config;
    slave_agent.cfg = cfg_env.slave_config;

    sb = axi4_lite_sb::type_id::create("sb",this);
    
endfunction : build_phase 
 
function void axi4_lite_env:: connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    //connect monitor to scb !!!
    if (cfg_env.has_master_agent == 1) begin
    master_agent.mon.axi4_lite_mon_w_analysis_port.connect(sb.w_mon_imp);
    end
    if (cfg_env.has_slave_agent == 1) begin    
    slave_agent.mon.axi4_lite_mon_r_analysis_port.connect(sb.r_mon_imp);
    end

endfunction : connect_phase

function void axi4_lite_env ::print_cfg();
   `uvm_info(get_type_name(), $sformatf ("The configuration that was set : \n%s", cfg_env.sprint()), UVM_MEDIUM)
endfunction : print_cfg


