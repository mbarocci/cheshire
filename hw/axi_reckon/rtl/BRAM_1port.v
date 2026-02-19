
  //  Xilinx Single Port No Change RAM
  //  This code implements a parameterizable single-port no-change memory where when data is written
  //  to the memory, the output remains unchanged.  This is the most power efficient write mode.
  //  If a reset or enable is not necessary, it may be tied off or removed from the code.
module BRAM1_inst #(
  parameter RAM_WIDTH = 128,                  // Specify RAM data width
  parameter RAM_DEPTH = 512,                  // Specify RAM depth (number of entries)
  parameter INIT_FILE = ""
  //parameter END_ADD = 511                       // Specify name/location of RAM initialization file if using one (leave blank if not)
)(
  input wire [clogb2(RAM_DEPTH-1)-1:0] ADD,  // Address bus, width determined from RAM_DEPTH
  input wire [RAM_WIDTH-1:0] DIN,           // RAM input data
  input wire CLK,                           // Clock
  input wire WE,                            // Write enable
  input wire CS,                            // RAM Enable, for additional power savings, disable port when not in use
  output wire [RAM_WIDTH-1:0] DOUT                   // RAM output data
);

  (* ram_style = "block" *) reg [RAM_WIDTH-1:0] RAM [RAM_DEPTH-1:0];
  reg [RAM_WIDTH-1:0] QA = {RAM_WIDTH{1'b0}};

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

  always @(posedge CLK) begin
    if (CS) begin
      if (WE) RAM[ADD] <= DIN;
      else QA <= RAM[ADD];
    end
  end
  //  The following code generates HIGH_PERFORMANCE (use output register) or LOW_LATENCY (no output register)
  // The following is a 1 clock cycle read latency at the cost of a longer clock-to-out timing
  assign DOUT = QA;
  //  The following function calculates the address width based on specified RAM depth
  function integer clogb2;
    input integer depth;
      for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
  endfunction
endmodule
