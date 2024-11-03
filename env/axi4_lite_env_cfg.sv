/*
    * * * Environment configuration class. By default it just defines that env will have 2 angets, and creates two agent configurations. One agent will be Master, other will be Slave.
*/
class axi4_lite_env_cfg extends uvm_object;       
    
    
    axi4_lite_cfg slave_config;
    axi4_lite_cfg master_config;    
    int has_master_agent;
    int has_slave_agent;
    

    extern function new(string name = "axi4_lite_env_cfg");
    `uvm_object_utils_begin(axi4_lite_env_cfg)
        `uvm_field_object(master_config, UVM_ALL_ON)
        `uvm_field_object(slave_config, UVM_ALL_ON)
        `uvm_field_int(has_master_agent, UVM_ALL_ON )
        `uvm_field_int(has_slave_agent, UVM_ALL_ON)      
    `uvm_object_utils_end
endclass

function axi4_lite_env_cfg::new(string name = "axi4_lite_env_cfg");
    super.new(name);
    master_config = axi4_lite_cfg::type_id::create ("master_config");
    slave_config = axi4_lite_cfg::type_id::create ("slave_config");
endfunction
