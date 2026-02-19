
  //  Xilinx Single Port Byte-Write Read First RAM
  //  This code implements a parameterizable single-port byte-write read-first memory where when data
  //  is written to the memory, the output reflects the prior contents of the memory location.
  //  If a reset or enable is not necessary, it may be tied off or removed from the code.
  //  Modify the parameters for the desired RAM characteristics.

module BRAM_inst_byte #(
  parameter NB_COL = 17,                       // Specify number of columns (number of bytes)
  parameter COL_WIDTH = 8,                  // Specify column width (byte width, typically 8 or 9)
  parameter RAM_DEPTH = 1024,                  // Specify RAM depth (number of entries)
  parameter INIT_FILE = ""                       // Specify name/location of RAM initialization file if using one (leave blank if not)
)(
  input  wire [clogb2(RAM_DEPTH-1)-1:0] ADDR,  // Address bus, width determined from RAM_DEPTH
  input  wire [(NB_COL*COL_WIDTH)-1:0] DATA_in,  // RAM input data
  input  wire CLK,                           // Clock
  input  wire [NB_COL-1:0] WE,               // Byte-write enable
  input  wire CS,                            // RAM Enable, for additional power savings, disable port when not in use
  input  wire RST_reg,                           // Output reset (does not affect memory contents)
  input  wire EN_reg,                         // Output register enable
  output wire [(NB_COL*COL_WIDTH)-1:0] DATA_out          // RAM output data
);
  reg [(NB_COL*COL_WIDTH)-1:0] RAM_inst [RAM_DEPTH-1:0];
  reg [(NB_COL*COL_WIDTH)-1:0] RAM_DATA_out = {(NB_COL*COL_WIDTH){1'b0}};

  // The following code either initializes the memory values to a specified file or to all zeros to match hardware
  generate
    if (INIT_FILE != "") begin: use_init_file
      initial
        $readmemh(INIT_FILE, RAM_inst, 0, RAM_DEPTH-1);
    end else begin: init_bram_to_zero
      integer ram_index;
      initial
        for (ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1)
          RAM_inst[ram_index] = {(NB_COL*COL_WIDTH){1'b0}};
    end
  endgenerate

  always @(posedge CLK)
    if (CS) begin
      RAM_DATA_out <= RAM_inst[ADDR];
    end

  generate
  genvar i;
  for (i = 0; i < NB_COL; i = i+1) begin: byte_write
    always @(posedge CLK)
      if (CS) begin
        if (WE[i]) begin
          RAM_inst[ADDR][(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= DATA_in[(i+1)*COL_WIDTH-1:i*COL_WIDTH];
        end
      end
  end
  endgenerate

  //  The following code generates HIGH_PERFORMANCE (use output register) or LOW_LATENCY (no output register)
      // The following is a 1 clock cycle read latency at the cost of a longer clock-to-out timing
  
  assign DATA_out = RAM_DATA_out;

  // always @(posedge CLK)
  //   DATA_out <= RST_reg ? 32'd0 : (EN_reg ? RAM_DATA_out : DATA_out);

  //  The following function calculates the address width based on specified RAM depth
    function integer clogb2;
        input integer depth;
      for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
    endfunction
endmodule
