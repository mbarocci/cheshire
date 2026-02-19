//  Xilinx True Dual Port RAM Read First Dual Clock
//  This code implements a parameterizable true dual port memory (both ports can read and write).
//  The behavior of this RAM is when data is written, the prior memory contents at the write
//  address are presented on the output port.  If the output data is
//  not needed during writes or the last read value is desired to be retained,
//  it is suggested to use a no change RAM as it is more power efficient.
//  If a reset or enable is not necessary, it may be tied off or removed from the code.

module BRAM2_we_inst #(

    parameter NB_COL = 16, // Specify number of columns
    parameter COL_WIDTH = 8, // Specify number of rows
    parameter RAM_WIDTH = 128,  // Specify RAM data width
    parameter RAM_DEPTH = 512,  // Specify RAM depth (number of entries)
    //parameter RAM_PERFORMANCE = "LOW_LATENCY", // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    parameter INIT_FILE = ""   // Specify name/location of RAM initialization file if using one
    //parameter END_ADD   = 512
) (
    input wire [clogb2(RAM_DEPTH-1)-1:0] ADDRA,  // Port A address bus, width determined from RAM_DEPTH
    input wire [clogb2(RAM_DEPTH-1)-1:0] ADDRB,  // Port B address bus, width determined from RAM_DEPTH
    input wire [(NB_COL*COL_WIDTH)-1:0] DINA,  // Port A RAM input data
    input wire [(NB_COL*COL_WIDTH)-1:0] DINB,  // Port B RAM input data
    input wire CLKA,  // Port A clock
    input wire CLKB,  // Port B clock
    input wire [NB_COL-1:0] WEA,  // Port A write enable
    input wire [NB_COL-1:0] WEB,  // Port B write enable
    input wire CSA, // Port A RAM Enable, for additional power savings, disable port when not in use
    input wire CSB, // Port B RAM Enable, for additional power savings, disable port when not in use
    input wire RSTA,                           // Port A output reset (does not affect memory contents)
    input wire RSTB,                           // Port B output reset (does not affect memory contents)
    input wire REGENA,                         // Port A output register enable
    input wire REGENB,                         // Port B output register enable
    output wire [(NB_COL*COL_WIDTH)-1:0] DOUTA,  // Port A RAM output data
    output wire [(NB_COL*COL_WIDTH)-1:0] DOUTB  // Port B RAM output data
);

  (* ram_style = "block" , ram_decomp = "power" *) reg [(NB_COL*COL_WIDTH)-1:0] RAM [RAM_DEPTH-1:0];

  reg [(NB_COL*COL_WIDTH)-1:0] QRA = {RAM_WIDTH{1'b0}};
  reg [(NB_COL*COL_WIDTH)-1:0] QRB = {RAM_WIDTH{1'b0}};

  // The following code either initializes the memory values to a specified file or to all zeros to match hardware
  generate
    if (INIT_FILE != "") begin : g_use_init_file
      initial $readmemh(INIT_FILE, RAM, 0, RAM_DEPTH-1);
    end else begin : g_init_bram_to_zero
      integer ram_index;
      initial
        for (ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1)
          RAM[ram_index] = {(NB_COL*COL_WIDTH){1'b0}};
    end
  endgenerate

  always @(posedge CLKA)
    if (CSA) QRA <= RAM[ADDRA];

  always @(posedge CLKB)
    if (CSB) QRB <= RAM[ADDRB];

  assign DOUTA = QRA;
  assign DOUTB = QRB;

  generate
  genvar i;
    for (i = 0; i < NB_COL; i = i+1) begin: g_byte_write
       always @(posedge CLKA)
         if (CSA)
           if (WEA[i])
             RAM[ADDRA][(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= DINA[(i+1)*COL_WIDTH-1:i*COL_WIDTH];
       always @(posedge CLKB)
         if (CSB)
           if (WEB[i])
             RAM[ADDRB][(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= DINB[(i+1)*COL_WIDTH-1:i*COL_WIDTH];
    end
  endgenerate

  //  The following function calculates the address width based on specified RAM depth
  function integer clogb2;
    input integer depth;
    for (clogb2 = 0; depth > 0; clogb2 = clogb2 + 1) depth = depth >> 1;
  endfunction

endmodule
