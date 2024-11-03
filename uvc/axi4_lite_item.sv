
typedef enum{READ, WRITE} operation_t;

class axi4_lite_item#(int ADDR = 32, int DATA = 32) extends uvm_sequence_item; 
 
	rand bit [ADDR-1:0] addr; 	//  address
	rand bit [DATA-1:0] data; 	// data
	rand bit [DATA/8-1:0] wstrb;// write strobes
	rand bit [1:0] prot; 		// access permissions
	rand operation_t operation;
	rand int delay; 			// delay between transactions

	rand bit [1:0] resp;

	//Register variables in factory
    `uvm_object_utils_begin(axi4_lite_item) 
		`uvm_field_enum(operation_t, operation, UVM_ALL_ON)
		`uvm_field_int(addr,  UVM_ALL_ON)
		`uvm_field_int(data,  UVM_ALL_ON)
		`uvm_field_int(wstrb, UVM_ALL_ON)
		`uvm_field_int(prot,  UVM_ALL_ON)
		`uvm_field_int(delay, UVM_ALL_ON)
		`uvm_field_int(resp,  UVM_ALL_ON)
    `uvm_object_utils_end
    extern function new(string name = "axi4_lite_item");
endclass // axi4_lite_item

function axi4_lite_item::new(string name = "axi4_lite_item");
    super.new(name);
endfunction 


