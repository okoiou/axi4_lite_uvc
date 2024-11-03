class axi4_lite_master_sequence#(int ADDR = 32, int DATA = 32) extends uvm_sequence #(axi4_lite_item);
 	//declare p_sequencer
    `uvm_declare_p_sequencer(axi4_lite_master_sequencer)
    
	//item fields
	rand bit [ADDR-1:0] 	addr; 
	rand bit [DATA-1:0] 	data; 
	rand bit [DATA/8-1:0] 	wstrb; 
	rand bit [1:0] 			prot;
	rand operation_t 		operation;	
	rand int 				delay;
	rand bit [1:0] 			resp;
	//add to factory
`	uvm_object_utils_begin(axi4_lite_master_sequence)
		`uvm_field_enum(operation_t, operation, UVM_ALL_ON)
		`uvm_field_int(addr,  UVM_ALL_ON)
		`uvm_field_int(data,  UVM_ALL_ON)
		`uvm_field_int(wstrb, UVM_ALL_ON)
		`uvm_field_int(prot,  UVM_ALL_ON)
		`uvm_field_int(delay, UVM_ALL_ON)
		`uvm_field_int(resp,	 UVM_ALL_ON)
	`uvm_object_utils_end

	//constraints
	constraint delay_c {soft delay inside{[0:5]};}

	//Declare the virtual interface handle and cfg
	virtual axi4_lite_if axi4_lite_vif;
    axi4_lite_cfg cfg;

    extern function new(string name = "axi4_lite_master_sequence");
    extern virtual task pre_body();   
    extern virtual task body();   
    extern virtual task post_body();  

endclass // axi4_lite_master_sequence

//-------------------------------------------------------------------
function axi4_lite_master_sequence::new(string name = "axi4_lite_master_sequence");
    super.new(name);
endfunction //axi4_lite_master_sequence::new

//-------------------------------------------------------------------
task axi4_lite_master_sequence::body();
    
    uvm_config_db#(axi4_lite_cfg)::set(null, "*", "cfg", p_sequencer.cfg);
    if (!uvm_config_db#(axi4_lite_cfg)::get(p_sequencer,"", "cfg",cfg))
        `uvm_fatal("body", "cfg wasn't set through config db"); 

	//get virtual interface
	if(!uvm_config_db#(virtual axi4_lite_if)::get(uvm_root::get(), "", "axi4_lite_vif", axi4_lite_vif)) begin
		`uvm_fatal(get_type_name(), "Failed to get virtual interface.")
	end

	//ensure that the sequencer is not null
    if (p_sequencer == null) begin
        `uvm_fatal(get_type_name(), "p_sequencer is null. Cannot proceed.")
    end

	//wait (delay) clk cycles
	repeat(delay) @(posedge axi4_lite_vif.system_clock);
	$display("wait %0d clk cycles", delay);

	//create, randomize and send the req
	req = axi4_lite_item::type_id::create("req");
	start_item(req);
	if(!req.randomize()with{
			operation 	== local::operation;
			addr 		== local::addr;
			data 		== local::data;
			wstrb 		== local::wstrb;
			prot		== local::prot;
			resp		== local::resp;
	})begin
		`uvm_error(get_type_name(), "Randomization failed for b2gfifo_item!")
	end
	finish_item(req);

	`uvm_info("axi4_lite_master_sequence", $sformatf("Sequence %s is over", this.get_name()), UVM_LOW)	
endtask 

//-------------------------------------------------------------------
task axi4_lite_master_sequence::pre_body();
    uvm_test_done.raise_objection(this);
endtask

//-------------------------------------------------------------------
task axi4_lite_master_sequence::post_body();
    uvm_test_done.drop_objection(this);
endtask



