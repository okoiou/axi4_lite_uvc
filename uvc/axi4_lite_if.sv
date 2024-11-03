
interface axi4_lite_if #(parameter ADDR = 32, parameter DATA = 32)(input bit system_clock, input bit reset_n);
    
    //Write address channel
	logic AWVALID;
	logic AWREADY;
	logic [ADDR-1:0] AWADDR;
	logic [1:0] AWPROT;

	//Write data channel
	logic WVALID;
	logic WREADY;
	logic [DATA-1:0] WDATA;
	logic [DATA/8-1:0] WSTRB;

	//Write response channel
	logic BVALID;
	logic BREADY;
	logic [1:0] BRESP;

	//Read address channel
	logic ARVALID;
	logic ARREADY;
	logic [ADDR-1:0] ARADDR;
	logic [1:0] ARPROT;

	//Read data channel
	logic RVALID;
	logic RREADY;
	logic [DATA-1:0] RDATA;
	logic [1:0] RRESP;

endinterface   
    


