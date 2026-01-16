//  Xilinx True Dual Port RAM Read First Dual Clock
//  This code implements a parameterizable true dual port memory (both ports can read and write).
//  The behavior of this RAM is when data is written, the prior memory contents at the write
//  address are presented on the output port.  If the output data is
//  not needed during writes or the last read value is desired to be retained,
//  it is suggested to use a no change RAM as it is more power efficient.
//  If a reset or enable is not necessary, it may be tied off or removed from the code.

module BRAM2_inst #(

    parameter RAM_WIDTH = 128,  // Specify RAM data width
    parameter RAM_DEPTH = 512,  // Specify RAM depth (number of entries)
    //parameter RAM_PERFORMANCE = "LOW_LATENCY", // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    parameter INIT_FILE = ""   // Specify name/location of RAM initialization file if using one
    //parameter END_ADD   = 512
) (
    input wire [clogb2(RAM_DEPTH-1)-1:0] ADDRA,  // Port A address bus, width determined from RAM_DEPTH
    input wire [clogb2(RAM_DEPTH-1)-1:0] ADDRB,  // Port B address bus, width determined from RAM_DEPTH
    input wire [RAM_WIDTH-1:0] DINA,  // Port A RAM input data
    input wire [RAM_WIDTH-1:0] DINB,  // Port B RAM input data
    input wire CLK,  // Port A clock
    input wire CLKN,  // Port B clock
    input wire WEA,  // Port A write enable
    input wire WEB,  // Port B write enable
    input wire CSA, // Port A RAM Enable, for additional power savings, disable port when not in use
    input wire CSB, // Port B RAM Enable, for additional power savings, disable port when not in use
    input wire RSTA,                           // Port A output reset (does not affect memory contents)
    input wire RSTB,                           // Port B output reset (does not affect memory contents)
    input wire REGENA,                         // Port A output register enable
    input wire REGENB,                         // Port B output register enable
    output wire [RAM_WIDTH-1:0] DOUTA,  // Port A RAM output data
    output wire [RAM_WIDTH-1:0] DOUTB  // Port B RAM output data
);

  (* ram_style = "block" *) reg [RAM_WIDTH-1:0] RAM [RAM_DEPTH-1:0];

  reg [RAM_WIDTH-1:0] QRA = {RAM_WIDTH{1'b0}};
  reg [RAM_WIDTH-1:0] QRB = {RAM_WIDTH{1'b0}};

  // The following code either initializes the memory values to a specified file or to all zeros to match hardware
  generate
    if (INIT_FILE != "") begin : g_use_init_file
      initial $readmemh(INIT_FILE, RAM, 0, RAM_DEPTH-1);
    end else begin : g_init_bram_to_zero
      integer ram_index;
      initial
        for (ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1)
          RAM[ram_index] = {RAM_WIDTH{1'b0}};
    end
  endgenerate

  always @(posedge CLK)
    if (CSA) begin
      if (WEA) RAM[ADDRA] <= DINA;
      else QRA <= RAM[ADDRA];
    end

  always @(posedge CLKN)
    if (CSB) begin
      if (WEB) RAM[ADDRB] <= DINB;
      else QRB <= RAM[ADDRB];
    end


  assign DOUTA = QRA;
  assign DOUTB = QRB;

  //  The following function calculates the address width based on specified RAM depth
  function integer clogb2;
    input integer depth;
    for (clogb2 = 0; depth > 0; clogb2 = clogb2 + 1) depth = depth >> 1;
  endfunction

endmodule
