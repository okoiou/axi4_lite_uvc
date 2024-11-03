
typedef enum{FIRST_READ, FIRST_WRITE} policy_type_enum;
typedef enum {RETURN_RANDOM, RETURN_X} read_behavior_type_enum;
class axi4_lite_cfg extends uvm_object;  

//  Enables protocol checks
    rand bit has_checks;
    rand bit ready_high;
//  Enables coverage  
    rand bit has_coverage;
    rand agent_type_enum agent_type; // master (0) or slave (1)
	
	rand policy_type_enum policy; //policy for read and write at the same time from same addr
	rand read_behavior_type_enum read_behavior; //behavior on reading empty address
//  Simulation timeout
    time test_time_out = 100000000;

//  Default constraints 
    constraint axi4_lite_cfg_default_cst {        
        soft has_coverage == 1;
        soft has_checks == 1;
		soft policy == FIRST_WRITE;
		soft read_behavior ==1;
    }
//------------------------------------------------------------------------------------------------------------
// Shorthand macros
//------------------------------------------------------------------------------------------------------------
    `uvm_object_utils_begin(axi4_lite_cfg)
		`uvm_field_enum(policy_type_enum, policy, UVM_ALL_ON)
		`uvm_field_enum(read_behavior_type_enum, read_behavior, UVM_ALL_ON)
        `uvm_field_int (has_coverage, UVM_ALL_ON)
        `uvm_field_int (has_checks, UVM_ALL_ON)
    `uvm_object_utils_end
    
    extern function new(string name = "axi4_lite_cfg");

endclass // axi4_lite_cfg

//-------------------------------------------------------------------------------------------------------------
function axi4_lite_cfg::new(string name = "axi4_lite_cfg");
    super.new(name);
endfunction // new


