
`timescale 1 ns / 1 ps

module AXI4_RF_slave_lite_v1_0_S00_AXI #
(
	// Users to add parameters here
	parameter integer N1    	= 32,
	parameter integer N2		= 8,
	// User parameters ends
	// Do not modify the parameters beyond this line

	// Width of S_AXI data bus
	parameter integer C_S_AXI_DATA_WIDTH	= 32,
	// Width of S_AXI address bus
	parameter integer C_S_AXI_ADDR_WIDTH	= 8
)
(
	// Users to add ports here
	// Programmable number of input ports

	input wire  [31:0] in_reg0,
	input wire  [31:0] in_reg1,
	input wire  [31:0] in_reg2,
	input wire  [31:0] in_reg3,
	input wire  [31:0] in_reg4,
	input wire  [31:0] in_reg5,
	input wire  [31:0] in_reg6,
	input wire  [31:0] in_reg7,
	input wire  [31:0] in_reg8,
	input wire  [31:0] in_reg9,
	input wire  [31:0] in_reg10,
	input wire  [31:0] in_reg11,
	input wire  [31:0] in_reg12,
	input wire  [31:0] in_reg13,
	input wire  [31:0] in_reg14,
	input wire  [31:0] in_reg15,
	input wire  [31:0] in_reg16,
	input wire  [31:0] in_reg17,
	input wire  [31:0] in_reg18,
	input wire  [31:0] in_reg19,
	input wire  [31:0] in_reg20,
	input wire  [31:0] in_reg21,
	input wire  [31:0] in_reg22,
	input wire  [31:0] in_reg23,
	input wire  [31:0] in_reg24,
	input wire  [31:0] in_reg25,
	input wire  [31:0] in_reg26,
	input wire  [31:0] in_reg27,
	input wire  [31:0] in_reg28,
	input wire  [31:0] in_reg29,
	input wire  [31:0] in_reg30,
	input wire  [31:0] in_reg31,

	output wire [31:0] out_reg0,
	output wire [31:0] out_reg1,
	output wire [31:0] out_reg2,
	output wire [31:0] out_reg3,
	output wire [31:0] out_reg4,
	output wire [31:0] out_reg5,
	output wire [31:0] out_reg6,
	output wire [31:0] out_reg7,

	input  wire [31:0] gpio_i,
	output wire [31:0] gpio_o,

	input  wire [31:0] cycles_counter_0,
	input  wire [31:0] cycles_counter_1,
	input  wire [31:0] cycles_counter_2,
	input  wire [31:0] cycles_counter_3,
	input  wire [31:0] cycles_counter_4,
	input  wire [31:0] cycles_counter_5,
	input  wire [31:0] cycles_counter_6,
	input  wire [31:0] cycles_counter_7,

	output wire [31:0] counter_config_0, 
	output wire [31:0] counter_config_1, 
	output wire [31:0] counter_config_2, 
	output wire [31:0] counter_config_3, 
	output wire [31:0] counter_config_4, 
	output wire [31:0] counter_config_5, 
	output wire [31:0] counter_config_6, 
	output wire [31:0] counter_config_7, 
	// User ports ends
	// Do not modify the ports beyond this line

	// Global Clock Signal
	input wire  S_AXI_ACLK,
	// Global Reset Signal. This Signal is Active LOW
	input wire  S_AXI_ARESETN,
	// Write address (issued by master, acceped by Slave)
	input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
	// Write channel Protection type. This signal indicates the
		// privilege and security level of the transaction, and whether
		// the transaction is a data access or an instruction access.
	input wire [2 : 0] S_AXI_AWPROT,
	// Write address valid. This signal indicates that the master signaling
		// valid write address and control information.
	input wire  S_AXI_AWVALID,
	// Write address ready. This signal indicates that the slave is ready
		// to accept an address and associated control signals.
	output wire  S_AXI_AWREADY,
	// Write data (issued by master, acceped by Slave) 
	input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
	// Write strobes. This signal indicates which byte lanes hold
		// valid data. There is one write strobe bit for each eight
		// bits of the write data bus.    
	input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
	// Write valid. This signal indicates that valid write
		// data and strobes are available.
	input wire  S_AXI_WVALID,
	// Write ready. This signal indicates that the slave
		// can accept the write data.
	output wire  S_AXI_WREADY,
	// Write response. This signal indicates the status
		// of the write transaction.
	output wire [1 : 0] S_AXI_BRESP,
	// Write response valid. This signal indicates that the channel
		// is signaling a valid write response.
	output wire  S_AXI_BVALID,
	// Response ready. This signal indicates that the master
		// can accept a write response.
	input wire  S_AXI_BREADY,
	// Read address (issued by master, acceped by Slave)
	input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
	// Protection type. This signal indicates the privilege
		// and security level of the transaction, and whether the
		// transaction is a data access or an instruction access.
	input wire [2 : 0] S_AXI_ARPROT,
	// Read address valid. This signal indicates that the channel
		// is signaling valid read address and control information.
	input wire  S_AXI_ARVALID,
	// Read address ready. This signal indicates that the slave is
		// ready to accept an address and associated control signals.
	output wire  S_AXI_ARREADY,
	// Read data (issued by slave)
	output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
	// Read response. This signal indicates the status of the
		// read transfer.
	output wire [1 : 0] S_AXI_RRESP,
	// Read valid. This signal indicates that the channel is
		// signaling the required read data.
	output wire  S_AXI_RVALID,
	// Read ready. This signal indicates that the master can
		// accept the read data and response information.
	input wire  S_AXI_RREADY
);

	// AXI4LITE signals
	(* dont_touch = "yes" *) (* mark_debug = "true" *) reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	(* dont_touch = "yes" *) (* mark_debug = "true" *) reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	//localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	//localparam integer OPT_MEM_ADDR_BITS = 1;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 4
	//reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;
	//reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;
	//reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
	//reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;

	localparam NR = N1+N2;
	localparam NG = NR +3;
	localparam NC = 8
	localparam NCF = NG+2*NC

	(* dont_touch = "yes" *) (* mark_debug = "true" *) reg [C_S_AXI_DATA_WIDTH-1:0] read_only_regs  [ 0:N1-1];  // Read-only registers
	(* dont_touch = "yes" *) (* mark_debug = "true" *) reg [C_S_AXI_DATA_WIDTH-1:0] write_only_regs [N1:NR-1]; // Write-only registers
	(* dont_touch = "yes" *) (* mark_debug = "true" *) reg [C_S_AXI_DATA_WIDTH-1:0] gpio_regs       [NR:NG-1]; // GPIOs internal reg
	(* dont_touch = "yes" *) (* mark_debug = "true" *) reg [C_S_AXI_DATA_WIDTH-1:0] counter_config  [NG:NCF-NC-1];  // counters configurations
	(* dont_touch = "yes" *) (* mark_debug = "true" *) reg [C_S_AXI_DATA_WIDTH-1:0] cycles_counter  [NCF-NC:NCF-1];  // configurable counters
													
	integer	 byte_index, i;

	// I/O Connections assignments

	assign S_AXI_AWREADY = axi_awready;
	assign S_AXI_WREADY	 = axi_wready;
	assign S_AXI_BRESP	 = axi_bresp;
	assign S_AXI_BVALID	 = axi_bvalid;
	assign S_AXI_ARREADY = axi_arready;
	assign S_AXI_RRESP	 = axi_rresp;
	assign S_AXI_RVALID	 = axi_rvalid;
	assign S_AXI_RDATA	 = axi_rdata;
		// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	reg aw_en;
	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_awready <= 1'b0;
			aw_en <= 1'b1;
		end 
		else
		begin    
			if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
			begin
				// slave is ready to accept write address when 
				// there is a valid write address and write data
				// on the write address and data bus. This design 
				// expects no outstanding transactions. 
				axi_awready <= 1'b1;
				aw_en <= 1'b0;
			end
			else if (S_AXI_BREADY && axi_bvalid)
				begin
					aw_en <= 1'b1;
					axi_awready <= 1'b0;
				end
			else           
			begin
				axi_awready <= 1'b0;
			end
		end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_awaddr <= 0;
		end 
		else
		begin    
			if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
			begin
				// Write Address latching 
				axi_awaddr <= S_AXI_AWADDR;
			end
		end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_wready <= 1'b0;
		end 
		else
		begin    
			if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
			begin
				// slave is ready to accept write data when 
				// there is a valid write address and write data
				// on the write address and data bus. This design 
				// expects no outstanding transactions. 
				axi_wready <= 1'b1;
			end
			else
			begin
				axi_wready <= 1'b0;
			end
		end 
	end
	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	/*
	generate
		genvar j;
		for (j = N_READONLY_REG; j < (2**(C_S_AXI_ADDR_WIDTH)); j = j + 1) begin : CASE_GEN
			always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
				if (S_AXI_ARESETN == 1'b0) begin
					write_only_regs[j] <= 0;
				end else begin
					case ( (S_AXI_AWVALID) ? S_AXI_AWADDR[C_S_AXI_ADDR_WIDTH-1:0] : axi_awaddr[C_S_AXI_ADDR_WIDTH-1:0] )
						j: begin
							for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1) begin
								if (S_AXI_WSTRB[byte_index] == 1) begin
									write_only_regs[j][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
								end
							end
						end
						default: begin
							write_only_regs[j] <= write_only_regs[j];
						end
					endcase
				end
			end
		end
	endgenerate
	*/

	wire write_enable;
	assign write_enable = S_AXI_AWVALID && S_AXI_WVALID && axi_awready && axi_wready;

	reg [31:0] out_reg_r [N1:NR-1]; // Read-only registers
	reg [31:0] counter_config_reg [NG:NG+NC-1]; // Read-only registers


	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		for (i = N1; i < NR; i = i + 1) begin
			write_only_regs[i] <= write_only_regs[i];
		end
		if (S_AXI_ARESETN == 1'b0) begin
			for (i = N1; i < NR; i = i + 1) begin
				write_only_regs[i]    <= 0;
			end
			for (i = NG; i < NG+NC; i = i + 1) begin
				counter_config_reg[i] <= 0;
			end
		end else begin
			for (i = N1; i < NR; i = i + 1) begin
				if (write_enable) begin
					if (axi_awaddr == i) begin
						for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1) begin
							if (S_AXI_WSTRB[byte_index] == 1) begin
								write_only_regs[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
							end
						end
					end
				end else begin
					write_only_regs[i] <= write_only_regs[i];
				end
			end
			for (i = NG; i < NG+NC; i = i + 1) begin
				if (write_enable) begin
					if (axi_awaddr == i) begin
						for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1) begin
							if (S_AXI_WSTRB[byte_index] == 1) begin
								counter_config_reg[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
							end
						end
					end
				end else begin
					counter_config_reg[i] <= counter_config_reg[i];
				end
			end
		end
	end

	

	always @(posedge S_AXI_ACLK) begin
		if (S_AXI_ARESETN == 1'b0) begin
			for (i = N1; i < NR; i = i + 1) begin
				out_reg_r[i] <= 32'd0; // Default value
			end
			for (i = NG; i < NG+NC; i = i + 1) begin
				counter_config[i] <= 0;
			end
		end
		else begin
			for (i = N1; i < NR; i = i + 1) begin
				out_reg_r[i] <= write_only_regs[i];
			end
			for (i = NG; i < NG+NC; i = i + 1) begin
				counter_config[i] <= counter_config_reg[i];
			end
		end
	end

	assign out_reg0 = out_reg_r[N1];
	assign out_reg1 = out_reg_r[N1+1];
	assign out_reg2 = out_reg_r[N1+2];
	assign out_reg3 = out_reg_r[N1+3];
	assign out_reg4 = out_reg_r[N1+4];
	assign out_reg5 = out_reg_r[N1+5];
	assign out_reg6 = out_reg_r[N1+6];
	assign out_reg7 = out_reg_r[N1+7];

	assign counter_config_0 = counter_config[NG+0];
	assign counter_config_1 = counter_config[NG+1];
	assign counter_config_2 = counter_config[NG+2];
	assign counter_config_3 = counter_config[NG+3];
	assign counter_config_4 = counter_config[NG+4];
	assign counter_config_5 = counter_config[NG+5];
	assign counter_config_6 = counter_config[NG+6];
	assign counter_config_7 = counter_config[NG+7]

		// Implement write response logic generation
		// The write response and response valid signals are asserted by the slave 
		// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
		// This marks the acceptance of address and indicates the status of 
		// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_bvalid  <= 0;
			axi_bresp   <= 2'b0;
		end 
		else
		begin    
			if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
			begin
				// indicates a valid write response is available
				axi_bvalid <= 1'b1;
				axi_bresp  <= 2'b0; // 'OKAY' response 
			end                   // work error responses in future
			else
			begin
				if (S_AXI_BREADY && axi_bvalid) 
				//check if bready is asserted while bvalid is high) 
				//(there is a possibility that bready is always asserted high)   
				begin
					axi_bvalid <= 1'b0; 
				end  
			end
		end
	end  

		// Implement axi_arready generation
		// axi_arready is asserted for one S_AXI_ACLK clock cycle when
		// S_AXI_ARVALID is asserted. axi_awready is 
		// de-asserted when reset (active low) is asserted. 
		// The read address is also latched when S_AXI_ARVALID is 
		// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_arready <= 1'b0;
			axi_araddr  <= 32'b0;
		end 
		else
		begin    
			if (~axi_arready && S_AXI_ARVALID)
			begin
				// indicates that the slave has acceped the valid read address
				axi_arready <= 1'b1;
				// Read address latching
				axi_araddr  <= S_AXI_ARADDR;
			end
			else
			begin
				axi_arready <= 1'b0;
			end
		end 
	end       

		// Implement axi_arvalid generation
		// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
		// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
		// data are available on the axi_rdata bus at this instance. The 
		// assertion of axi_rvalid marks the validity of read data on the 
		// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
		// is deasserted on reset (active low). axi_rresp and axi_rdata are 
		// cleared to zero on reset (active low).  
	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_rvalid <= 0;
			axi_rresp  <= 0;
		end 
		else
		begin    
			if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
			begin
				// Valid read data is available at the read data bus
				axi_rvalid <= 1'b1;
				axi_rresp  <= 2'b0; // 'OKAY' response
			end   
			else if (axi_rvalid && S_AXI_RREADY)
			begin
				// Read data is accepted by the master
				axi_rvalid <= 1'b0;
			end                
		end
	end    
			
			//assign S_AXI_RDATA = (axi_araddr < N1) ? read_only_regs[axi_araddr] : 32'hDEADBEEF;
			
		// Add user logic here

		wire slv_reg_rden;
		assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

	reg [31:0] debugReg_sync      [31:0];
	reg [31:0] counters_sync      [NCF-NC:NCF-1];
	
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (S_AXI_ARESETN == 1'b0) begin
			for (i = NCF-NC; i < NCF; i = i + 1) begin
				counters_sync[i] <= 32'd0; // Default value
			end
		end
		else begin
			counters_sync[0] <= cycles_counter_0;
			counters_sync[1] <= cycles_counter_1;
			counters_sync[2] <= cycles_counter_2;
			counters_sync[3] <= cycles_counter_3;
			counters_sync[4] <= cycles_counter_4;
			counters_sync[5] <= cycles_counter_5;
			counters_sync[6] <= cycles_counter_6;
			counters_sync[7] <= cycles_counter_7;
		end
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (S_AXI_ARESETN == 1'b0) begin
			for (i = 0; i < 32; i = i + 1) begin
				debugReg_sync[i] <= 32'd0; // Default value
			end
		end
		else begin
			debugReg_sync[0] <= in_reg0;
			debugReg_sync[1] <= in_reg1;
			debugReg_sync[2] <= in_reg2;
			debugReg_sync[3] <= in_reg3;
			debugReg_sync[4] <= in_reg4;
			debugReg_sync[5] <= in_reg5;
			debugReg_sync[6] <= in_reg6;
			debugReg_sync[7] <= in_reg7;
			debugReg_sync[8] <= in_reg8;
			debugReg_sync[9] <= in_reg9;
			debugReg_sync[10] <= in_reg10;
			debugReg_sync[11] <= in_reg11;
			debugReg_sync[12] <= in_reg12;
			debugReg_sync[13] <= in_reg13;
			debugReg_sync[14] <= in_reg14;
			debugReg_sync[15] <= in_reg15;
			debugReg_sync[16] <= in_reg16;
			debugReg_sync[17] <= in_reg17;
			debugReg_sync[18] <= in_reg18;
			debugReg_sync[19] <= in_reg19;
			debugReg_sync[20] <= in_reg20;
			debugReg_sync[21] <= in_reg21;
			debugReg_sync[22] <= in_reg22;
			debugReg_sync[23] <= in_reg23;
			debugReg_sync[24] <= in_reg24;
			debugReg_sync[25] <= in_reg25;
			debugReg_sync[26] <= in_reg26;
			debugReg_sync[27] <= in_reg27;
			debugReg_sync[28] <= in_reg28;
			debugReg_sync[29] <= in_reg29;
			debugReg_sync[30] <= in_reg30;
			debugReg_sync[31] <= in_reg31;
		end
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (S_AXI_ARESETN == 1'b0) begin
			for (i = NCF-NC; i < NCF; i = i + 1) begin
				cycles_counter[i] <= 32'd0; // Default value
			end
		end else begin
			for (i = NCF-NC; i < NCF; i = i + 1) begin
				cycles_counter[i] <= counters_sync[i];
			end
		end
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		for (i = 0; i < N1; i = i + 1) begin
			read_only_regs[i] <= 32'd0; // Default value
		end
		if (S_AXI_ARESETN == 1'b0) begin
			for (i = 0; i < N1; i = i + 1) begin
				read_only_regs[i] <= 32'd0; // Default value
			end
		end else begin
			for (i = 0; i < N1; i = i + 1) begin
				read_only_regs[i] <= debugReg_sync[i];
			end
			// space for other signals to read with read_only_reg
		end
	end

	always @( posedge S_AXI_ACLK ) begin
	if ( S_AXI_ARESETN == 1'b0 )
		begin
		axi_rdata  <= 0;
		end 
	else
		begin    
		// When there is a valid read address (S_AXI_ARVALID) with 
		// acceptance of read address by the slave (axi_arready), 
		// output the read dada 
		if (slv_reg_rden)
			begin
			axi_rdata <= (axi_araddr < N1)                     		? read_only_regs[axi_araddr]  :
						 (axi_araddr >= N1 && axi_araddr < NR) 		? write_only_regs[axi_araddr] :
						 (axi_araddr >= NR && axi_araddr < NG) 		? gpio_regs[axi_araddr]       :
						 (axi_araddr >= NG && axi_araddr < NG+NC) 	? counter_config[axi_araddr]  :
						 (axi_araddr >= NG+NC && axi_araddr < NCF) 	? cycles_counter[axi_araddr]  :
						 32'hDEADBEEF;    // register read data
			end   
		end
	end

	// GPIO LOGIC
	// gpio_conf: 1 if bit i is input, 0 if output
	// GPIo[nr+2] = TOGGLE
	
	wire [C_S_AXI_DATA_WIDTH-1:0] gpio_conf, gpio_toggle;
	reg gpio_toggle_flag;
	reg [1:0] gpio_toggle_cnt;
	
	assign gpio_conf   = gpio_regs[NR];
	//assign gpio_o      = (gpio_regs[NR+1] & ~gpio_conf);
	//SRAM[A] <= (D & M) | (SRAM[A] & ~M)

	wire [31:0] gpio_o_t;
	reg  [31:0] gpio_o_reg;

    genvar g;
    generate
        for (g = 0; g < 32; g = g + 1) begin
			assign gpio_o_t[g] = ~gpio_conf[g] ? ( (gpio_toggle[g] & |gpio_toggle_cnt) ? ~gpio_regs[NR+1][g] : gpio_regs[NR+1][g]) : 1'b0;
		end
    endgenerate

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (S_AXI_ARESETN == 1'b0) begin
			gpio_o_reg <= 32'd0;
		end else begin
			gpio_o_reg <= gpio_o_t;
		end
	end
	
	assign gpio_o = gpio_o_reg;

	assign gpio_toggle = gpio_regs[NR+2]; // TO BE IMPLEMENTED
	//assign gpio_toggle = 32'd0;
	
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (S_AXI_ARESETN == 1'b0) begin
			gpio_toggle_cnt <= 1'b0;
		end else begin
			if (gpio_toggle_flag == 1'b1) begin
				gpio_toggle_cnt <= 2'b10;
			end else begin
				gpio_toggle_cnt <= gpio_toggle_cnt >>> 1;
			end
		end
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	begin
		if (S_AXI_ARESETN == 1'b0) begin
			for (i = NR; i < NG; i = i + 1) begin
				gpio_regs[i] <= 0;
				gpio_toggle_flag <= 1'b0;
			end
		end else begin
		    if (write_enable) begin
                case (axi_awaddr)
                  NR : begin
                      for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1) begin
                        if (S_AXI_WSTRB[byte_index] == 1) begin
                            gpio_regs[NR][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                        end
                      end
                  end
                  
                  NR+1: begin
                      for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1) begin
                        if (S_AXI_WSTRB[byte_index] == 1) begin
                            gpio_regs[NR+1][(byte_index*8) +: 8] <= (S_AXI_WDATA[(byte_index*8) +: 8]       & ~gpio_conf[(byte_index*8) +: 8]) |
                                                                    (gpio_regs[NR+1][(byte_index*8) +: 8]   &  gpio_conf[(byte_index*8) +: 8]);
                        end
                      end
                  end

				  NR+2: begin
					  for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1) begin
						if (S_AXI_WSTRB[byte_index] == 1) begin
							gpio_regs[NR+2][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8] & ~gpio_conf[(byte_index*8) +: 8];
						end
					  end
					  gpio_toggle_flag <= 1'b1;
				  end

				  default: begin
					  gpio_regs[NR]   <= gpio_regs[NR];
					  gpio_regs[NR+1] <= gpio_regs[NR+1];
					  gpio_regs[NR+2] <= gpio_regs[NR+2];
					  gpio_toggle_flag <= 1'b0;
				  end

                endcase
            end else begin
				gpio_regs[NR+2] <=  gpio_regs[NR+2];
                gpio_regs[NR+1] <= (gpio_regs[NR+1] & ~gpio_conf) | (gpio_i & gpio_conf);
		        gpio_regs[NR]   <=  gpio_regs[NR];
		        gpio_toggle_flag <= 1'b0;
		    end
		end
	end
	
	// User logic ends
    
endmodule
