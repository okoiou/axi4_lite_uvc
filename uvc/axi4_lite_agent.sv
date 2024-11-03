
class axi4_lite_agent#(parameter int ADDR = 32,parameter int DATA = 32) extends uvm_agent;
    
    `uvm_component_utils(axi4_lite_agent#(ADDR,DATA))

    virtual axi4_lite_if#(ADDR, DATA) axi4_lite_vif;
      
    axi4_lite_cfg                 			cfg;
	axi4_lite_monitor#(ADDR, DATA)   	 	mon;
    axi4_lite_master_driver#(ADDR, DATA)   	m_drv;
    axi4_lite_master_sequencer    			write_seqr, read_seqr;
	axi4_lite_slave_driver#(ADDR, DATA)   	s_drv;
	axi4_lite_slave_sequencer     			s_seqr;
   
    extern function new (string name, uvm_component parent);
    extern virtual function void build_phase (uvm_phase phase);
    extern virtual function void connect_phase (uvm_phase phase);
    
endclass //axi4_lite_agent

//-------------------------------------------------------------------------------------------------------------
function axi4_lite_agent::new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("axi4_lite_agent", "axi4_lite UVC", UVM_LOW);
endfunction

//-------------------------------------------------------------------------------------------------------------
function void axi4_lite_agent::build_phase(uvm_phase phase);
    
    super.build_phase(phase);

    if (!uvm_config_db#(virtual axi4_lite_if#(ADDR, DATA))::get(this, "*", "axi4_lite_vif", axi4_lite_vif)) begin
        `uvm_fatal("build_phase_axi4_lite_agent", "interface was not set");
    end else 
        `uvm_info("build_phase_axi4_lite_agent", "axi4_lite_if was set through config db", UVM_LOW); 

    `uvm_info("AGENT", $sformatf("cfg.agent_type = %0b", cfg.agent_type), UVM_LOW)

     if (get_is_active() == UVM_ACTIVE && cfg.agent_type == MASTER) begin // Agent is configured as Master
        this.m_drv = axi4_lite_master_driver#(ADDR, DATA)::type_id::create("m_drv",this);
        this.write_seqr = axi4_lite_master_sequencer::type_id::create("write_seqr",this);
		this.read_seqr = axi4_lite_master_sequencer::type_id::create("read_seqr",this);
        `uvm_info("build_phase_master_agent", "Master driver and sequencer created.", UVM_LOW);
    end 
    if (get_is_active() == UVM_ACTIVE && cfg.agent_type == SLAVE) begin // Agent is configured as Slave
        this.s_drv = axi4_lite_slave_driver#(ADDR, DATA)::type_id::create("s_drv",this);
		this.s_seqr = axi4_lite_slave_sequencer::type_id::create("s_seqr",this);
        `uvm_info("build_phase_master_agent", "Slave driver and sequencer created.", UVM_LOW);
    end 
    
	mon = axi4_lite_monitor#(ADDR, DATA)::type_id::create("mon", this);
endfunction // axi4_lite_master_agent::buid_phase

//-------------------------------------------------------------------------------------------------------------
function void axi4_lite_agent::connect_phase(uvm_phase phase);
    if (get_is_active() == UVM_ACTIVE && cfg.agent_type == MASTER) begin  // Agent is configured as Master
        m_drv.seq_item_port.connect(write_seqr.seq_item_export);
		m_drv.seq_item_port2.connect(read_seqr.seq_item_export);
        `uvm_info("connect_phase_axi4_lite_agent", "master driver connected.", UVM_LOW);
    end
   if (get_is_active() == UVM_ACTIVE && cfg.agent_type == SLAVE) begin  // Agent is configured as Slave
        s_drv.seq_item_port.connect(s_seqr.seq_item_export);
        `uvm_info("connect_phase_axi4_lite_agent", "slave driver connected.", UVM_LOW);
    end
   //  axi4_lite_vif.axi4_lite_baud_rate_value <= cfg.axi4_lite_baud_rate_divisor;
endfunction // axi4_lite_agent::connect_phase

