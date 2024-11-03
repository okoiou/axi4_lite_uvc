
class axi4_lite_coverage extends uvm_component;
	`uvm_component_param_utils(axi4_lite_coverage)
	
    	axi4_lite_cfg cfg; 
	
    	//Write transaction coverage group
    	covergroup axi4_lite_cg_write_trans with function sample(axi4_lite_item item);
		option.per_instance = 1;
		data_value: coverpoint item.data{
			bins min_value 	= {32'h00000000};  
			bins max_value 	= {32'hFFFFFFFF}; 
			bins low_range 	= {[32'h00000000 : 32'h000003FF]}; 
			bins high_range	= {[32'hFFF00000 : 32'hFFFFFFFF]};  
			bins mid_range 	= {[32'h00010000 : 32'h0001FFFF]};  
		}

		addr_value: coverpoint item.addr{
			bins min_value 	= {32'h00000000};  
			bins max_value 	= {32'hFFFFFFFF}; 
			bins low_range 	= {[32'h00000000 : 32'h000003FF]}; 
			bins high_range	= {[32'hFFF00000 : 32'hFFFFFFFF]};  
			bins mid_range 	= {[32'h00010000 : 32'h0001FFFF]};  
		}

		wstrb_value: coverpoint item.wstrb{
			bins min_value 	= {0};  
			bins max_value	= {4'b1111};  
			bins low_range	= {[1:4'b0011]};  
			bins high_range	= {[4'b0011:4'b1111]};  
		}

		prot_value: coverpoint item.prot{
			bins UNPRIV 	= {2'b00};
			bins PRIV 	= {2'b01};
			bins SECURE 	= {2'b10};
			bins NON_SECURE	= {2'b11};
		}
		
		resp_value: coverpoint item.resp{
			bins OKAY 	= {2'b00};
			bins EXOKAY = {2'b01};
			bins SLVERR = {2'b10};
			bins DECERR = {2'b11};
		} 
    	endgroup
	//Read transaction coverage group
	covergroup axi4_lite_cg_read_trans with function sample(axi4_lite_item item);
	option.per_instance = 1;
		data_value: coverpoint item.data{
			bins min_value 	= {32'h00000000};  
			bins max_value 	= {32'hFFFFFFFF}; 
			bins low_range 	= {[32'h00000000 : 32'h000003FF]}; 
			bins high_range	= {[32'hFFF00000 : 32'hFFFFFFFF]};  
			bins mid_range 	= {[32'h00010000 : 32'h0001FFFF]};  
		}

		addr_value: coverpoint item.addr{
			bins min_value 	= {32'h00000000};  
			bins max_value 	= {32'hFFFFFFFF}; 
			bins low_range 	= {[32'h00000000 : 32'h000003FF]}; 
			bins high_range	= {[32'hFFF00000 : 32'hFFFFFFFF]};  
			bins mid_range 	= {[32'h00010000 : 32'h0001FFFF]};  
		}

		prot_value: coverpoint item.prot{
			bins UNPRIV 	= {2'b00};
			bins PRIV 		= {2'b01};
			bins SECURE 	= {2'b10};
			bins NON_SECURE	= {2'b11};
		}
		resp_value: coverpoint item.resp{
			bins OKAY 	= {2'b00};
			bins EXOKAY = {2'b01};
			bins SLVERR = {2'b10};
			bins DECERR = {2'b11};
		}
 
    	endgroup


	
    	extern function new(string name = "axi4_lite_coverage", uvm_component parent);
    	extern virtual function void build_phase(uvm_phase phase);
endclass
//-------------------------------------------------------------------------------------------------------------
function axi4_lite_coverage::new(string name = "axi4_lite_coverage", uvm_component parent);
    super.new(name, parent);
    axi4_lite_cg_write_trans = new();
	axi4_lite_cg_read_trans = new();
	
endfunction // axi4_lite_coverage::new
//-------------------------------------------------------------------------------------------------------------
function void  axi4_lite_coverage::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(axi4_lite_cfg)::get(this, "", "cfg", cfg))   
        `uvm_fatal("build_phase", "cfg wasn't set through config db");
endfunction // axi4_lite_coverage::build_phase

//-------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------

class axi4_lite_coverage_env extends uvm_component;
	`uvm_component_param_utils(axi4_lite_coverage_env)
	
    	axi4_lite_cfg cfg; 
	


	covergroup axi4_lite_cg_state with function sample(bit is_back_to_back_write, bit is_simultaneous, bit is_read_from_empty);
	option.per_instance = 1;
        	back_to_back_write: coverpoint is_back_to_back_write {
           	 	bins no_b2b = {0};
            		bins b2b = {1};
		}

		simultaneous_rw: coverpoint is_simultaneous {
		    bins no_simul = {0};
		    bins simul = {1};
		}

		read_from_empty: coverpoint is_read_from_empty {
		    bins no_empty = {0};
		    bins empty = {1};
		}
    	endgroup
	
    	extern function new(string name = "axi4_lite_coverage_env", uvm_component parent);
    	extern virtual function void build_phase(uvm_phase phase);
endclass
//-------------------------------------------------------------------------------------------------------------
function axi4_lite_coverage_env::new(string name = "axi4_lite_coverage_env", uvm_component parent);
    super.new(name, parent);
	axi4_lite_cg_state = new();
	
endfunction // axi4_lite_coverage_env::new
//-------------------------------------------------------------------------------------------------------------
function void  axi4_lite_coverage_env::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(axi4_lite_cfg)::get(this, "", "cfg", cfg))   
        `uvm_fatal("build_phase", "cfg wasn't set through config db");
endfunction // axi4_lite_coverage_env::build_phase

