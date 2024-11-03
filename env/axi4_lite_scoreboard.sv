`uvm_analysis_imp_decl(_w_mon) //write trans monitor
`uvm_analysis_imp_decl(_r_mon) //read trans monitor

class axi4_lite_sb#(int ADDR = 32, int DATA = 32) extends uvm_scoreboard;

    `uvm_component_utils(axi4_lite_sb)

    uvm_analysis_imp_w_mon #(axi4_lite_item, axi4_lite_sb) w_mon_imp; // write trans monitor
    uvm_analysis_imp_r_mon #(axi4_lite_item, axi4_lite_sb) r_mon_imp; // read trans monitor
  	virtual axi4_lite_if#(ADDR, DATA)   axi4_lite_vif;
    axi4_lite_item  write_trans, read_trans;

	bit[ADDR-1:0] exp_data[*];
	bit [1:0] exp_resp;
    int passCnt, failCnt;
	bit [ADDR-1:0] prev_write_addr;
    bit prev_write_valid;
    bit [ADDR-1:0] prev_read_addr;
    bit prev_read_valid;

	bit is_read_from_empty;
	bit is_back_to_back_write;

	axi4_lite_coverage_env    cov;
    
    function new(string name = "", uvm_component parent);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        w_mon_imp = new("w_mon_imp", this);
        r_mon_imp = new("r_mon_imp", this);

		if(!uvm_config_db#(virtual axi4_lite_if#(ADDR, DATA))::get(this, "", "axi4_lite_vif", axi4_lite_vif)) 
        `uvm_fatal("build_phase",{"virtual interface must be set for: ", get_full_name(),".axi4_lite_vif"});

		cov = axi4_lite_coverage_env::type_id::create("axi4_lite_coverage_env",this);
    endfunction    

    virtual function void write_r_mon(axi4_lite_item trans);
        `uvm_info("Scoreboard", "Just recieved read item from monitor", UVM_LOW)

		//read_trans = trans;
		

 		//check if the response is OK before proceeding
        if (trans.resp == 2'b00) begin  // response OK
            read_trans = trans;

			check_read_data();
            //coverage_inst.axi4_lite_cg_read_trans.sample(read_trans);

            // Check if reading from an unwritten (empty) address
            is_read_from_empty = !(exp_data.exists(read_trans.addr));

            // Sample state coverage
            cov.axi4_lite_cg_state.sample(0, prev_read_valid && prev_write_valid, is_read_from_empty);

            // Store current read state
            prev_read_addr = read_trans.addr;
            prev_read_valid = 1'b1;

            
        end else begin
            `uvm_warning("Scoreboard", "Ignoring read transaction due to non-OK response")
        end
    endfunction

    virtual function void write_w_mon(axi4_lite_item trans); 
        `uvm_info("Scoreboard", "Just recieved write item from monitor", UVM_LOW)

		

		//check if the response is OK before proceeding
        if (trans.resp == 2'b00) begin  //response OK
			write_trans = trans;
            //check for back-to-back write to the same address
            is_back_to_back_write =  (prev_write_addr == write_trans.addr);

            // Sample state coverage
            cov.axi4_lite_cg_state.sample(is_back_to_back_write, prev_read_valid && prev_write_valid, 0);

            // Store current write state
            prev_write_addr = write_trans.addr;
            prev_write_valid = 1'b1;
			//store write data 
            store_write_data();
        end else begin
            `uvm_warning("Scoreboard", "Ignoring write transaction due to non-OK response")
        end
    endfunction

    extern function void store_write_data();
	extern function void check_read_data();
	extern task run_phase(uvm_phase phase);
	extern task do_rst();

endclass

//-------------------------------------------------------------------------------------------------------------
function void axi4_lite_sb::store_write_data();
	//store expected data 	
	exp_data[write_trans.addr][7:0] 	= (write_trans.wstrb[0]) ? write_trans.data[7:0] 	: 'b0;
	exp_data[write_trans.addr][15:8]	= (write_trans.wstrb[1]) ? write_trans.data[15:8]	: 'b0;
	exp_data[write_trans.addr][23:16] 	= (write_trans.wstrb[2]) ? write_trans.data[23:16] 	: 'b0;
	exp_data[write_trans.addr][31:24] 	= (write_trans.wstrb[3]) ? write_trans.data[31:24] 	: 'b0;
					
    `uvm_info("Scoreboard - write", $sformatf("Data received = %0x", write_trans.data), UVM_NONE) 

endfunction 

//-------------------------------------------------------------------------------------------------------------
function void axi4_lite_sb::check_read_data();
	//compare actual with expected data
if ((exp_data.exists(read_trans.addr))) begin
 	if(read_trans.data == exp_data[read_trans.addr]) begin
        `uvm_info("Scoreboard - read", $sformatf("Read data match!"), UVM_NONE)
		`uvm_info("Scoreboard - read", $sformatf("Expected: %0h, Got: %0h", exp_data[read_trans.addr], read_trans.data), UVM_NONE)
        passCnt++;
    end
    else begin
        `uvm_error("Scoreboard - read", $sformatf("Read data mismatch, Expected: %0x, Got: %0x", exp_data[read_trans.addr], read_trans.data))
        failCnt++;
    end 
end
endfunction 

//------------------------------------------------------------------------------------------------------------

task axi4_lite_sb::run_phase(uvm_phase phase);
	super.run_phase(phase);
	
	forever begin			
		do_rst(); //reset all signals when reset is active 							
        prev_write_valid = 0;
        prev_read_valid = 0;
        @(posedge axi4_lite_vif.system_clock);
	end
endtask

//------------------------------------------------------------------------------------------------------------
task axi4_lite_sb::do_rst();
	@(negedge axi4_lite_vif.reset_n); //active low
		exp_data.delete();
		
endtask
