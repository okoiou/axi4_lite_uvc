
class axi4_lite_master_driver#(int ADDR = 32, int DATA = 32) extends uvm_driver #(axi4_lite_item);
    
    `uvm_component_utils(axi4_lite_master_driver#(ADDR,DATA))
    virtual axi4_lite_if#(ADDR, DATA)   axi4_lite_vif;

	uvm_seq_item_pull_port#(REQ, RSP) seq_item_port2;
    
	REQ write_trans, read_trans; //two different trans one for write and one for read
    axi4_lite_cfg    cfg;
	
    bit reset_flag 	= 0;
	bit r_trans_in_progress = 0; //flag to indicate if a read transaction is in progress
	bit w_trans_in_progress = 0; //flag to indicate if a writetransaction is in progress

    extern function new (string name, uvm_component parent);
    extern virtual function void build_phase (uvm_phase phase);
    extern virtual task run_phase (uvm_phase phase);
    extern virtual task do_init ();                    	
    extern virtual task reset_on_the_fly(); 
    extern virtual task do_drive(axi4_lite_item req); 
	extern virtual task drive_write_trans();
	extern virtual task drive_read_trans(); 			
 
endclass // axi4_lite_master_driver

//-------------------------------------------------------------------------------------------------------------
function axi4_lite_master_driver::new(string name, uvm_component parent);
    super.new(name, parent);
	seq_item_port2 = new("seq_item_port2", this);
endfunction // axi4_lite_master_driver::new

//-------------------------------------------------------------------------------------------------------------
function void axi4_lite_master_driver::build_phase(uvm_phase phase);
    super.build_phase(phase); 
    `uvm_info("build_phase","BUILD axi4_lite_MASTER_DRIVER",UVM_HIGH);
    if(!uvm_config_db#(virtual axi4_lite_if#(ADDR, DATA))::get(this, "", "axi4_lite_vif", axi4_lite_vif)) 
        `uvm_fatal("build_phase",{"virtual interface must be set for: ", get_full_name(),".axi4_lite_vif"});
    if (!uvm_config_db#(axi4_lite_cfg)::get(this, "", "cfg", cfg)) begin
        `uvm_fatal("build_phase", "cfg wasn't set through config db");
    end
endfunction // axi4_lite_master_driver::build_phase

//-------------------------------------------------------------------------------------------------------------
task axi4_lite_master_driver::run_phase(uvm_phase phase);

	@(posedge axi4_lite_vif.reset_n); // wait for reset to end
	repeat(3) @(posedge axi4_lite_vif.system_clock);  // wait 3 more clock cycles, just to be sure we're stable


    forever begin 
        
        //reset on the fly
        if (reset_flag) begin 
            @(posedge axi4_lite_vif.reset_n); // wait for reset to end
	        repeat(3) @(posedge axi4_lite_vif.system_clock); // wait 3 more clock cycles, just to be sure we're stable
            reset_flag = 0;
        end

		// initialize signals
		do_init();

		// enter regular flow loop
        fork 
            reset_on_the_fly(); 
            do_drive(req);
        join_any
        disable fork; 
		//complete the transactions
		if(w_trans_in_progress)begin
		    seq_item_port.item_done();
		    w_trans_in_progress = 0; //clear the flag 
		end
		if(r_trans_in_progress)begin
		    seq_item_port2.item_done();
		    r_trans_in_progress = 0; //clear the flag 
		end
    end   // of forever

endtask// axi4_lite_master_driver::run_phase

//-------------------------------------------------------------------------------------------------------------
task axi4_lite_master_driver::do_init();
	// initial values for if signals 
	// write address channel signals
	axi4_lite_vif.AWVALID 	<= 0;
	axi4_lite_vif.AWADDR 	<= 'b00;
	axi4_lite_vif.AWPROT 	<= 2'b00;

	// write data channel signals
	axi4_lite_vif.WVALID 	<= 0;
	axi4_lite_vif.WDATA 	<= 'b00;
	axi4_lite_vif.WSTRB 	<= 4'b00;

	// write response channel signals
	axi4_lite_vif.BREADY 	<= 0;

	// read address channel signals
	axi4_lite_vif.ARVALID 	<= 0;
	axi4_lite_vif.ARADDR 	<= 'b00;
	axi4_lite_vif.ARPROT 	<= 2'b00;

    @(posedge axi4_lite_vif.system_clock);
    `uvm_info("Driver", "do_init task executed", UVM_LOW)
endtask // axi4_lite_master_driver::do_init
//-------------------------------------------------------------------------------------------------------------
task axi4_lite_master_driver::do_drive(axi4_lite_item req);
	fork
		if(!w_trans_in_progress)
			drive_write_trans();
		if(!r_trans_in_progress)		
			drive_read_trans();
	join
    @(posedge axi4_lite_vif.system_clock);   
     `uvm_info("Driver", "do_drive task executed", UVM_LOW)

endtask //axi4_lite_master_driver::do_drive
//-------------------------------------------------------------------------------------------------------------

task axi4_lite_master_driver::reset_on_the_fly();   
    @(negedge axi4_lite_vif.reset_n);
    reset_flag = 1;

	axi4_lite_vif.AWVALID 	<=0;
	axi4_lite_vif.WVALID 	<=0;
	axi4_lite_vif.ARVALID 	<=0;
endtask // axi4_lite_master_driver::reset_on_the_fly
//-------------------------------------------------------------------------------------------------------------

task axi4_lite_master_driver::drive_write_trans();
	forever begin

		`uvm_info(get_name(), "Inside drive_write_trans()", UVM_LOW)
		seq_item_port.get_next_item(write_trans);
		w_trans_in_progress = 1; //write transaction starts
		`uvm_info(get_name(), "Write Packet received in master driver", UVM_LOW)
		write_trans.print();

		@(posedge axi4_lite_vif.system_clock);
		// drive prot
		axi4_lite_vif.AWPROT  = write_trans.prot;

		//drive address and control signals
		axi4_lite_vif.AWADDR = write_trans.addr;
		axi4_lite_vif.AWVALID = 1;
		`uvm_info(get_name(), "Asserted AWVALID", UVM_LOW)

		// wait for AWREADY and deassert AWVALID
		wait(axi4_lite_vif.AWREADY);
		@(posedge axi4_lite_vif.system_clock);
		axi4_lite_vif.AWVALID = 0;
		`uvm_info(get_name(), "Deasserted AWVALID", UVM_LOW)

		axi4_lite_vif.BRESP  = write_trans.resp;

		// drive the data
		axi4_lite_vif.WDATA  = write_trans.data;
		`uvm_info(get_name(), "DATA", UVM_LOW)
		// drive the data strobes
		axi4_lite_vif.WSTRB  = write_trans.wstrb;
		`uvm_info(get_name(), "STRB", UVM_LOW)

		// assert WVALID and BREADY
		axi4_lite_vif.WVALID = 1;
		
		
		// wait for WREADY and deassert WVALID
		wait(axi4_lite_vif.WREADY);
		@(posedge axi4_lite_vif.system_clock);
		axi4_lite_vif.WVALID = 0;
		`uvm_info(get_name(), "Deasserted WVALID", UVM_LOW)
		// write resp ready
		axi4_lite_vif.BREADY = 1;
		`uvm_info(get_name(), "asserted BREADY ", UVM_LOW)
		
		// wait for BVALID (write response) and deassert BREADY
		wait(axi4_lite_vif.BVALID);
		@(posedge axi4_lite_vif.system_clock);
		axi4_lite_vif.BREADY = 0;
		`uvm_info(get_name(), "Deasserted BREADY", UVM_LOW)

		seq_item_port.item_done();
		w_trans_in_progress = 0; //write transaction done
		`uvm_info(get_name(), "Write Packet done", UVM_LOW)

	end
endtask // axi4_lite_master_driver::drive_write_data

//-------------------------------------------------------------------------------------------------------------

task axi4_lite_master_driver::drive_read_trans();
	forever begin

		`uvm_info("DEBUG", "Inside drive_read_trans()", UVM_LOW)
		seq_item_port2.get_next_item(read_trans);
		r_trans_in_progress = 1; //read transaction starts
		`uvm_info(get_name(), "Read Packet received in master driver", UVM_LOW)
		read_trans.print();	

		@(posedge axi4_lite_vif.system_clock);
		// drive prot
		axi4_lite_vif.ARPROT  <= read_trans.prot;

		// send the read address
		axi4_lite_vif.ARADDR = read_trans.addr;

		// assert ARVALID
		axi4_lite_vif.ARVALID = 1;

		axi4_lite_vif.RRESP  = read_trans.resp;

		// wait for ARREADY and deassert ARVALID
		wait(axi4_lite_vif.ARREADY);
		@(posedge axi4_lite_vif.system_clock);
		axi4_lite_vif.ARVALID = 0;
		`uvm_info(get_name(), "Deasserted ARVALID", UVM_LOW)
		// assert RREADY
		axi4_lite_vif.RREADY = 1;

		wait(axi4_lite_vif.RVALID);
		@(posedge axi4_lite_vif.system_clock);
		axi4_lite_vif.RREADY =0;
		`uvm_info(get_name(), "Deasserted RREADY", UVM_LOW)

		seq_item_port2.item_done();
		r_trans_in_progress = 0; //read transaction done
		`uvm_info(get_name(), "Read Packet done", UVM_LOW)

	end
endtask // axi4_lite_master_driver::drive_read_trans



