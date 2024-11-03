
class axi4_lite_slave_driver#(int ADDR = 32, int DATA = 32) extends uvm_driver #(axi4_lite_item);
    
    `uvm_component_utils(axi4_lite_slave_driver#(ADDR,DATA))
    virtual axi4_lite_if#(ADDR, DATA)   axi4_lite_vif;
	
	axi4_lite_item#(ADDR, DATA) s_write_trans, s_read_trans;
    
	bit [DATA-1:0] mem [*];
    axi4_lite_cfg    cfg;
    bit reset_flag = 0;
	
    extern function new (string name, uvm_component parent);
    extern virtual function void build_phase (uvm_phase phase);
    extern virtual task run_phase (uvm_phase phase);
    extern virtual task do_init ();
    extern virtual task reset_on_the_fly();
	extern virtual task do_drive(axi4_lite_item req);    
	extern virtual task do_write_trans();
    extern virtual task do_read_trans();

    
endclass // axi4_lite_slave_driver

//-------------------------------------------------------------------------------------------------------------
function axi4_lite_slave_driver::new(string name, uvm_component parent);
    super.new(name, parent);
	s_write_trans = new("s_write_trans");
	s_read_trans = new("s_read_trans");
endfunction // axi4_lite_slave_driver::new

//-------------------------------------------------------------------------------------------------------------
function void axi4_lite_slave_driver::build_phase(uvm_phase phase);
    super.build_phase(phase); 
    `uvm_info("build_phase","BUILD axi4_lite_slave_DRIVER",UVM_HIGH);
    if(!uvm_config_db#(virtual axi4_lite_if#(ADDR, DATA))::get(this, "", "axi4_lite_vif", axi4_lite_vif)) 
        `uvm_fatal("build_phase",{"virtual interface must be set for: ", get_full_name(),".axi4_lite_vif"});
    if (!uvm_config_db#(axi4_lite_cfg)::get(this, "", "cfg", cfg)) begin
        `uvm_fatal("build_phase", "cfg wasn't set through config db");
    end
endfunction // axi4_lite_slave_driver::build_phase

//-------------------------------------------------------------------------------------------------------------
task axi4_lite_slave_driver::run_phase(uvm_phase phase);
    
	@(posedge axi4_lite_vif.reset_n);
	repeat(3) @(posedge axi4_lite_vif.system_clock);

	
    forever begin 
  		// wait for out of reset
        if (reset_flag) begin 
            @(posedge axi4_lite_vif.reset_n); // wait for reset to end
	        repeat(3) @(posedge axi4_lite_vif.system_clock); // wait 3 more clock cycles, just to be sure we're stable
            reset_flag = 0;
        end
		// initialize signals
		do_init();
		seq_item_port.get_next_item(req);
		// enter regular flow loop
        fork 
            reset_on_the_fly(); 
            do_drive(req);
        join_any
        disable fork; 
		seq_item_port.item_done();
    end   // of forever
endtask// axi4_lite_slave_driver::run_phase

//-------------------------------------------------------------------------------------------------------------

task axi4_lite_slave_driver::do_init();
	//Initialize the signals
	axi4_lite_vif.AWREADY    <= 0; 	
    axi4_lite_vif.WREADY     <= 0;
    axi4_lite_vif.BVALID     <= 1; 	
	axi4_lite_vif.ARREADY    <= 0;
    axi4_lite_vif.RVALID     <= 0;
    //axi4_lite_vif.RDATA      <= 'b00;
	//axi4_lite_vif.WSTRB      <= 'b11;
	

    @(posedge axi4_lite_vif.system_clock);  
    `uvm_info("Slave Driver", "do_init task executed", UVM_LOW)
endtask	// axi4_lite_slave_driver::do_init

//-------------------------------------------------------------------------------------------------------------
task axi4_lite_slave_driver::reset_on_the_fly();
    @(negedge axi4_lite_vif.reset_n);
    reset_flag = 1;
	axi4_lite_vif.RVALID     <= 0;
    axi4_lite_vif.RDATA      <= 'b00;
		mem.delete();
endtask	//axi4_lite_slave_driver::reset_on_the_fly

//-------------------------------------------------------------------------------------------------------------
task axi4_lite_slave_driver::do_drive(axi4_lite_item req);
	$display("inside do drive");
	repeat(req.delay)@(posedge axi4_lite_vif.system_clock);
	fork
		do_write_trans();		
		do_read_trans();
	join
    @(posedge axi4_lite_vif.system_clock);   
     `uvm_info("Driver", "do_drive task executed", UVM_LOW)
endtask //axi4_lite_master_driver::do_drive
//-------------------------------------------------------------------------------------------------------------
task axi4_lite_slave_driver::do_write_trans();
	`uvm_info("Slave Driver", "Inside do_write_trans", UVM_LOW)
	 // wait until the write address is valid
    wait(axi4_lite_vif.AWVALID)
    
    // Capture the write transaction details from the interface
    s_write_trans.addr   = axi4_lite_vif.AWADDR;

	// assert AWREADY
	axi4_lite_vif.AWREADY = 1;
	// wait a clk and deassert AWVALID
	@(posedge axi4_lite_vif.system_clock);
	axi4_lite_vif.AWREADY = 0;

	//read and write to the same addr
	if(axi4_lite_vif.ARVALID & (axi4_lite_vif.AWADDR == axi4_lite_vif.ARADDR)) begin
		if(cfg.policy == FIRST_READ)begin // first read and then write
			`uvm_info("Slave Driver", "first read and then write", UVM_LOW)
			wait(axi4_lite_vif.RVALID);
		end
	end
	wait(axi4_lite_vif.WVALID);
	if(axi4_lite_vif.BRESP == 2'b00) begin
		
		// Use the WSTRB signal to selectively write bytes of WDATA to memory	
		mem[s_write_trans.addr][7:0] 	= (axi4_lite_vif.WSTRB[0]) ? axi4_lite_vif.WDATA[7:0] 	: 'b0; 
		mem[s_write_trans.addr][15:8] 	= (axi4_lite_vif.WSTRB[1]) ? axi4_lite_vif.WDATA[15:8] 	: 'b0;
		mem[s_write_trans.addr][23:16] 	= (axi4_lite_vif.WSTRB[2]) ? axi4_lite_vif.WDATA[23:16] : 'b0;
		mem[s_write_trans.addr][31:24] 	= (axi4_lite_vif.WSTRB[3]) ? axi4_lite_vif.WDATA[31:24] : 'b0;
		
	end
	
	else begin
		`uvm_info("Slave Driver", "RESPONSE ERROR", UVM_LOW)
	end
	
	// assert WREADY
		axi4_lite_vif.WREADY = 1;	
	axi4_lite_vif.BVALID = 1;

	// wait until the write resp channel is ready to accept resp
	wait(axi4_lite_vif.BREADY)
	@(posedge axi4_lite_vif.system_clock);
	axi4_lite_vif.WREADY = 0;
	axi4_lite_vif.BVALID = 0;
	
	`uvm_info("Slave Driver", "read_write_data done", UVM_LOW)
endtask	//axi4_lite_slave_driver::read_write_data

//-------------------------------------------------------------------------------------------------------------
task axi4_lite_slave_driver::do_read_trans();
	`uvm_info("Slave Driver", "Inside do_read_trans", UVM_LOW)
	 // wait until the read address is valid
    wait(axi4_lite_vif.ARVALID);
    
    // Capture the read transaction details from the interface
    s_read_trans.addr   = axi4_lite_vif.ARADDR;

	// assert ARREADY
	axi4_lite_vif.ARREADY = 1;
	// wait a clk and deassert AWVALID
	@(posedge axi4_lite_vif.system_clock);
	axi4_lite_vif.ARREADY = 0;
	
	//read and write to the same addr
	if(axi4_lite_vif.AWVALID & (axi4_lite_vif.ARADDR == axi4_lite_vif.AWADDR)) begin
		if(cfg.policy == FIRST_WRITE)begin // first read and then write
			`uvm_info("Slave Driver", "first write and then read", UVM_LOW)
			wait(axi4_lite_vif.BVALID);
		end
	end
    if(axi4_lite_vif.RRESP == 2'b00) begin
		//check if the address is empty and respond accordingly
		if (!mem.exists(s_read_trans.addr)) begin
		    //address is empty, decide based on configuration whether to return a random value or 'X'
		    if (cfg.read_behavior == RETURN_RANDOM) begin
		        axi4_lite_vif.RDATA <= $urandom_range(0, 32'hFFFFFFFF); // Return random data
		    end else begin
		        axi4_lite_vif.RDATA <= 'x; // Return 'X' value
		    end
		end else begin
		    // Send the data stored in the memory back to the master
		    axi4_lite_vif.RDATA <= mem[s_read_trans.addr];
		end
		
	end
	else begin
		`uvm_info("Slave Driver", "RESPONSE ERROR", UVM_LOW)
	end

	// assert RVALID
	axi4_lite_vif.RVALID = 1;

	@(posedge axi4_lite_vif.system_clock);
	axi4_lite_vif.RVALID = 0;

	`uvm_info("Slave Driver", "do_read_trans done", UVM_LOW)
endtask	//axi4_lite_slave_driver::do_read_trans
