
class axi4_lite_monitor#(int ADDR = 32, int DATA = 32) extends uvm_monitor; 
   
   `uvm_component_utils(axi4_lite_monitor#(ADDR,DATA))

    virtual axi4_lite_if#(ADDR, DATA) axi4_lite_vif;
   
    axi4_lite_coverage    cov;
    axi4_lite_item#(DATA, ADDR)   write_trans, read_trans;
    axi4_lite_cfg         cfg;
   
    uvm_analysis_port#(axi4_lite_item)   axi4_lite_mon_r_analysis_port; //analysis port for read transactions
    uvm_analysis_port #(axi4_lite_item)  axi4_lite_mon_w_analysis_port; //analysis port for write transactions

  	//flags to track reset 	
    bit reset_flag 	= 0;

	//flags to track dependencies
	bit read_address_handshake_done = 0;
	bit write_address_handshake_done = 0;
	bit write_data_handshake_done = 0;
    
    extern function new (string name, uvm_component parent);
    extern virtual function void build_phase (uvm_phase phase);
    extern virtual task  run_phase(uvm_phase phase);  
    extern virtual task  do_monitor();
    extern virtual task  reset_on_the_fly();
	extern virtual task write_monitor();
	extern virtual task read_monitor();
	extern virtual task perform_checks();
    
endclass // axi4_lite_monitor_class

//-------------------------------------- 
//-----------------------------------------------------------------------
function axi4_lite_monitor::new (string name, uvm_component parent);
    super.new(name, parent);
endfunction   

//-------------------------------------------------------------------------------------------------------------
function void axi4_lite_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("build_phase","BUILD axi4_lite_MONITOR",UVM_MEDIUM);
    if(!uvm_config_db#(virtual axi4_lite_if#(ADDR, DATA))::get(this, "", "axi4_lite_vif", axi4_lite_vif)) 
        `uvm_fatal("build_phase",{"virtual interface must be set for: ",get_full_name(),".axi4_lite_vif"});

    if (!uvm_config_db#(axi4_lite_cfg)::get(this, "", "cfg",cfg)) begin
        `uvm_fatal("build_phase", "cfg wasn't set through config db");
    end

    axi4_lite_mon_w_analysis_port = new("axi4_lite_mon_w_analysis_port",this);
 	axi4_lite_mon_r_analysis_port = new("axi4_lite_mon_r_analysis_port",this);

    if (cfg.has_coverage) begin
        cov = axi4_lite_coverage::type_id::create("axi4_lite_coverage",this);
        cov.cfg = this.cfg;
    end  


    if (!cfg.has_checks)   
        `uvm_info("build_phase","CHECKERS DISABLED",UVM_LOW);
endfunction

//-------------------------------------------------------------------------------------------------------------
task  axi4_lite_monitor::run_phase(uvm_phase phase);
    
	//wait for reset
	@(posedge axi4_lite_vif.reset_n);
	repeat(3) @(posedge axi4_lite_vif.system_clock);
    forever begin
      	//reset on the fly
		if (reset_flag) begin
            @(posedge axi4_lite_vif.reset_n); // wait for reset to end
	        repeat(3) @(posedge axi4_lite_vif.system_clock); // wait 3 more clock cycles, just to be sure we're stable
            reset_flag = 0;
        end
		
		


		// enter regular flow loop
        fork 
            reset_on_the_fly(); 
            do_monitor();
			if(cfg.has_checks)
				perform_checks();
		
        join_any
        disable fork;
@(posedge axi4_lite_vif.system_clock); 
    end // of forever       
endtask


//-------------------------------------------------------------------------------------------------------------
task axi4_lite_monitor::reset_on_the_fly();  

    @(negedge axi4_lite_vif.reset_n);
    reset_flag = 1;
    `uvm_info("MONITOR","ASYNCHRONOUS RESET HAPPENED", UVM_LOW)
    
endtask //reset_on_the_fly*/
//-------------------------------------------------------------------------------------------------------------
task axi4_lite_monitor::do_monitor();
  
	fork
		write_monitor();
		read_monitor();		
	join
	
    @(posedge axi4_lite_vif.system_clock);  
    `uvm_info("Monitor", "do_monitor task executed", UVM_LOW)

endtask
//-------------------------------------------------------------------------------------------------------------
task axi4_lite_monitor::write_monitor();
	forever begin
		`uvm_info("Monitor", "inside write_monitor", UVM_LOW)
		write_trans = axi4_lite_item#(DATA, ADDR)::type_id::create("write_trans");
		`uvm_info("Monitor", "write_trans created ", UVM_LOW)

		//monitor write addr channel
		wait(axi4_lite_vif.AWVALID & axi4_lite_vif.AWREADY);
		
		write_trans.operation = WRITE;
		write_trans.addr = axi4_lite_vif.AWADDR;
		write_trans.prot = axi4_lite_vif.AWPROT;
		
		//monitor write data channel
		wait(axi4_lite_vif.WVALID && axi4_lite_vif.WREADY)
		write_trans.data = axi4_lite_vif.WDATA;
		write_trans.wstrb = axi4_lite_vif.WSTRB;
		`uvm_info("Monitor", "inside write_monitor data done", UVM_LOW)

		//monitor write resp channel
		wait(axi4_lite_vif.BVALID & axi4_lite_vif.BREADY)
		`uvm_info("Monitor", "wait resp write_monitor ", UVM_LOW)

		write_trans.resp = axi4_lite_vif.BRESP;
		
		axi4_lite_mon_w_analysis_port.write(write_trans); // sending sampled data to scoreboard
		
		`uvm_info("Monitor", "write trans sent to scb", UVM_LOW)
	
		cov.axi4_lite_cg_write_trans.sample(write_trans); // sampling for coverage
	end
endtask
//-------------------------------------------------------------------------------------------------------------
task axi4_lite_monitor::read_monitor();
	forever begin
	read_trans = axi4_lite_item#(DATA, ADDR)::type_id::create("read_trans");
	read_trans.operation = READ;
	//monitor read address channel
	wait(axi4_lite_vif.ARREADY && axi4_lite_vif.ARVALID)

	read_trans.addr = axi4_lite_vif.ARADDR;
	read_trans.prot = axi4_lite_vif.ARPROT;

	//monitor read data channel
	wait(axi4_lite_vif.RVALID && axi4_lite_vif.RREADY)
	
	@(negedge axi4_lite_vif.system_clock); 
	read_trans.data = axi4_lite_vif.RDATA;
	read_trans.resp = axi4_lite_vif.RRESP;

	`uvm_info(get_name(), $sformatf("[MON] RDATA SAMPLED : %h", axi4_lite_vif.RDATA), UVM_LOW)
	
	axi4_lite_mon_r_analysis_port.write(read_trans); // sending sampled data to scoreboard
	`uvm_info("S_Monitor", "read trans sent to scb", UVM_LOW)
	cov.axi4_lite_cg_read_trans.sample(read_trans); // sampling for coverage
	end
endtask
//-------------------------------------------------------------------------------------------------------------
task axi4_lite_monitor::perform_checks();
	$display("Inside perform checks");
	fork
      //Track read address and data channel
		forever begin
        	//Check read address handshake
		    @(posedge axi4_lite_vif.system_clock iff(axi4_lite_vif.ARVALID && axi4_lite_vif.ARREADY)) begin
		      `uvm_info(get_name(), $sformatf("Read Address Handshake: addr = 0x%0h", axi4_lite_vif.ARADDR), UVM_LOW)
		      read_address_handshake_done = 1;
		    end
		end
		forever begin
        	//Check read data handshake 
		    @(posedge axi4_lite_vif.system_clock iff(axi4_lite_vif.RVALID && axi4_lite_vif.RREADY)) begin
			  if (!read_address_handshake_done) begin
			    `uvm_error(get_name(), "RVALID asserted before ARVALID and ARREADY handshake")
			  end else begin
			    `uvm_info(get_name(), $sformatf("Read Data Handshake: data = 0x%0h", axi4_lite_vif.RDATA), UVM_LOW)
			    read_address_handshake_done = 0;  //Reset the handshake flag
		      end   
			end
		end

      	//Track write address and data channels 
		forever begin
		    //Check write address handshake (AW channel)
		    @(posedge axi4_lite_vif.system_clock iff(axi4_lite_vif.AWVALID && axi4_lite_vif.AWREADY)) begin
		      `uvm_info(get_name(), $sformatf("Write Address Handshake: addr = 0x%0h", axi4_lite_vif.AWADDR), UVM_LOW)
		      write_address_handshake_done = 1;
		    end 
		end
		forever begin
		    //Check write data handshake 
		    @(posedge axi4_lite_vif.system_clock iff(axi4_lite_vif.WVALID && axi4_lite_vif.WREADY)) begin
		      `uvm_info(get_name(), $sformatf("Write Data Handshake: data = 0x%0h", axi4_lite_vif.WDATA), UVM_LOW)
		      write_data_handshake_done = 1;
		    end 
		end
		forever begin
        	//Check write response handshake 
		    @(posedge axi4_lite_vif.system_clock iff(axi4_lite_vif.BVALID && axi4_lite_vif.BREADY)) begin
			  if (!(write_address_handshake_done && write_data_handshake_done)) begin
			    if (!write_address_handshake_done && !write_data_handshake_done) begin
			      `uvm_error(get_name(), "BVALID asserted before both AWVALID, AWREADY and WVALID, WREADY handshakes")
			    end else if (!write_address_handshake_done) begin
			      `uvm_error(get_name(), "BVALID asserted before AWVALID and AWREADY handshake")
			    end else if (!write_data_handshake_done) begin
			      `uvm_error(get_name(), "BVALID asserted before WVALID and WREADY handshake")
			    end
			  end else begin
			    `uvm_info(get_name(), $sformatf("Write Response Handshake: resp = 0x%0h", axi4_lite_vif.BRESP), UVM_LOW)
			  end
			  //Reset the handshake flags
			  write_address_handshake_done = 0;
			  write_data_handshake_done = 0;
			end
		end 
    join
	$display("fork_join done");
	 

endtask
