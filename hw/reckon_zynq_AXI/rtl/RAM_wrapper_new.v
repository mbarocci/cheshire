module RAM_interface #(

    parameter WINP_RAM_WIDTH = 128,
    parameter WINP_RAM_DEPTH = 4096,
    parameter WINP_INIT_FILE = "",
    //parameter WINP_END_ADD = 4096,

    parameter WREC_RAM_WIDTH = 128,
    parameter WREC_RAM_DEPTH = 4096,
    parameter WREC_INIT_FILE = "",
    //parameter WREC_END_ADD = 4096,

    parameter WOUT_RAM_WIDTH = 128,
    parameter WOUT_RAM_DEPTH = 512,
    parameter WOUT_INIT_FILE = "",
    //parameter WOUT_END_ADD = 4096,

    parameter NEUR_RAM_WIDTH = 128,
    parameter NEUR_RAM_DEPTH = 128,
    parameter NEUR_INIT_FILE = ""
    //parameter NEUR_END_ADD = 4096

) (
     input  wire                                CLK,
    ////////////////////////////////////////////////////////////
     input  wire [clogb2(WINP_RAM_DEPTH-1)-1:0] winp_addr,
     input  wire [          WINP_RAM_WIDTH-1:0] winp_din,
     input  wire                                winp_we,
     input  wire                                winp_cs,
     input  wire [          WINP_RAM_WIDTH-1:0] winp_mask,
     output wire [          WINP_RAM_WIDTH-1:0] winp_dout,

     input  wire [clogb2(WREC_RAM_DEPTH-1)-1:0] wrec_addr,
     input  wire [          WREC_RAM_WIDTH-1:0] wrec_din,
     input  wire                                wrec_we,
     input  wire                                wrec_cs,
     input  wire [          WREC_RAM_WIDTH-1:0] wrec_mask,
     output wire [          WREC_RAM_WIDTH-1:0] wrec_dout,

     input  wire [clogb2(WOUT_RAM_DEPTH-1)-1:0] wout_addr,
     input  wire [          WOUT_RAM_WIDTH-1:0] wout_din,
     input  wire                                wout_we,
     input  wire                                wout_cs,
     input  wire [          WOUT_RAM_WIDTH-1:0] wout_mask,
     output wire [          WOUT_RAM_WIDTH-1:0] wout_dout,

     input  wire [clogb2(NEUR_RAM_DEPTH-1)-1:0] neur_addr,
     input  wire [          NEUR_RAM_WIDTH-1:0] neur_din,
     input  wire                                neur_we,
     input  wire                                neur_cs,
     input  wire [          NEUR_RAM_WIDTH-1:0] neur_mask,
     output wire [          NEUR_RAM_WIDTH-1:0] neur_dout
);
  
  integer i;
  genvar n;

  //  input weights RAM
  
  wire [WINP_RAM_WIDTH / 8-1:0] winp_we_byte;
  
  generate
    for (n=0; n< WINP_RAM_WIDTH / 8; n= n+1) begin: winp_gen
        assign winp_we_byte[n] = winp_we & |winp_mask[n*8 +: 8];
    end
  endgenerate

  BRAM_inst_byte #(
      .NB_COL(WINP_RAM_WIDTH / 8),
      .COL_WIDTH(8),
      .RAM_DEPTH(WINP_RAM_DEPTH),
      .INIT_FILE(WINP_INIT_FILE)
  ) SRAM_winp (
      .ADDR(winp_addr),
      .DATA_in (winp_din),
      .CLK  (CLK),
      .WE  (winp_we_byte),
      .CS  (winp_cs),
      .RST_reg      (),
      .EN_reg    (),
      .DATA_out(winp_dout)
  );

  // Recurrent weights SRAM   
  
  wire [WREC_RAM_WIDTH / 8-1:0] wrec_we_byte;
  
  generate
    for (n=0; n< WREC_RAM_WIDTH / 8; n= n+1) begin: wrec_gen
        assign wrec_we_byte[n] = wrec_we & |wrec_mask[n*8 +: 8];
    end
  endgenerate
  
  BRAM_inst_byte #(
      .NB_COL(WREC_RAM_WIDTH / 8),
      .COL_WIDTH(8),
      .RAM_DEPTH(WREC_RAM_DEPTH),
      .INIT_FILE(WREC_INIT_FILE)
  ) SRAM_wrec (
      .ADDR(wrec_addr),
      .DATA_in (wrec_din),
      .CLK  (CLK),
      .WE  (wrec_we_byte),
      .CS  (wrec_cs),
      .RST_reg      (),
      .EN_reg    (),
      .DATA_out(wrec_dout)
  );

  // Output weights SRAM
  
  wire [WOUT_RAM_WIDTH / 8-1:0] wout_we_byte;
  
  generate
    for (n=0; n< WOUT_RAM_WIDTH / 8; n= n+1) begin: wout_we_gen
        assign wout_we_byte[n] = wout_we & |wout_mask[n*8 +: 8];
    end
  endgenerate

  BRAM_inst_byte #(
      .NB_COL(WOUT_RAM_WIDTH / 8),
      .COL_WIDTH(8),
      .RAM_DEPTH(WOUT_RAM_DEPTH),
      .INIT_FILE(WOUT_INIT_FILE)
  ) SRAM_wout (
      .ADDR(wout_addr),
      .DATA_in (wout_din),
      .CLK  (CLK),
      .WE  (wout_we_byte),
      .CS  (wout_cs),
      .RST_reg      (),
      .EN_reg    (),
      .DATA_out(wout_dout)
  );

  // Neurons SRAM
  
  localparam NEUR_BYTE_WIDTH = 8;

  wire [15:0] membrane_in_n, membrane_in_n1, membrane_out_n, membrane_out_n1;
  wire [11:0] inp_trace_in_n, inp_trace_in_n1, inp_trace_out_n, inp_trace_out_n1;
  wire [11:0] rec_trace_in_n, rec_trace_in_n1, rec_trace_out_n, rec_trace_out_n1;
  wire [ 9:0] out_trace_in_n, out_trace_in_n1, out_trace_out_n, out_trace_out_n1;
  wire [15:0] threshold_in, threshold_out;
  wire [11:0] alphaLSB_in, alphaLSB_out;

  assign membrane_in_n   = neur_din[15:0];
  assign membrane_in_n1  = neur_din[65:50];

  assign inp_trace_in_n  = neur_din[27:16];
  assign inp_trace_in_n1 = neur_din[77:66];
  
  assign rec_trace_in_n  = neur_din[39:28];
  assign rec_trace_in_n1 = neur_din[89:78];

  assign out_trace_in_n  = neur_din[49:40];
  assign out_trace_in_n1 = neur_din[99:90];
  
  assign threshold_in    = neur_din[115:100];
  assign alphaLSB_in     = neur_din[127:116];

  wire [19:0]                     neur_we_byte;
  wire [NEUR_BYTE_WIDTH*20 -1 :0] neur_din_new, neur_dout_new;

  assign neur_din_new[15:0]    = membrane_in_n;
  assign neur_din_new[31:16]   = {4'b0,inp_trace_in_n};
  assign neur_din_new[47:32]   = {4'b0,rec_trace_in_n};
  assign neur_din_new[63:48]   = {6'b0,out_trace_in_n};
  assign neur_din_new[79:64]   = membrane_in_n1;
  assign neur_din_new[95:80]   = {4'b0,inp_trace_in_n1};
  assign neur_din_new[111:96]  = {4'b0,rec_trace_in_n1};
  assign neur_din_new[127:112] = {6'b0,out_trace_in_n1};
  assign neur_din_new[143:128] = threshold_in;
  assign neur_din_new[159:144] = {4'b0,alphaLSB_in};

  assign neur_we_byte[1:0]     = {2{neur_we & &neur_mask[15:0]}};
  assign neur_we_byte[3:2]     = {2{neur_we & &neur_mask[27:16]}};
  assign neur_we_byte[5:4]     = {2{neur_we & &neur_mask[39:28]}};
  assign neur_we_byte[7:6]     = {2{neur_we & &neur_mask[49:40]}};
  assign neur_we_byte[9:8]     = {2{neur_we & &neur_mask[65:50]}};
  assign neur_we_byte[11:10]   = {2{neur_we & &neur_mask[77:66]}};
  assign neur_we_byte[13:12]   = {2{neur_we & &neur_mask[89:78]}};
  assign neur_we_byte[15:14]   = {2{neur_we & &neur_mask[99:90]}};
  assign neur_we_byte[17:16]   = {2{neur_we & &neur_mask[115:100]}};
  assign neur_we_byte[19:18]   = {2{neur_we & &neur_mask[127:116]}}; 
  
  assign membrane_out_n   = neur_dout_new[15:0];
  assign inp_trace_out_n  = neur_dout_new[27:16];
  assign rec_trace_out_n  = neur_dout_new[43:32];
  assign out_trace_out_n  = neur_dout_new[57:48];
  assign membrane_out_n1  = neur_dout_new[79:64];
  assign inp_trace_out_n1 = neur_dout_new[91:80];
  assign rec_trace_out_n1 = neur_dout_new[107:96];
  assign out_trace_out_n1 = neur_dout_new[121:112];
  assign threshold_out    = neur_dout_new[143:128];
  assign alphaLSB_out     = neur_dout_new[155:144];

  assign neur_dout = {alphaLSB_out, threshold_out, out_trace_out_n1, rec_trace_out_n1, inp_trace_out_n1, membrane_out_n1, out_trace_out_n, rec_trace_out_n, inp_trace_out_n, membrane_out_n};


  // wire [NEUR_RAM_WIDTH +8 -1:0]   neur_din_new;
  // wire [NEUR_RAM_WIDTH +8 -1:0]   neur_dout_new;
  // wire [NEUR_RAM_WIDTH / 8 + 1 -1:0] neur_we_byte;
  // wire [NEUR_RAM_WIDTH +8 -1:0]   neur_mask_new;
  
  // assign neur_mask_new = {{2{1'b0}},neur_mask[127:50],{6{1'b0}},neur_mask[49:0]};
  // assign neur_din_new = {{2{1'b0}},neur_din[127:50],{6{1'b0}},neur_din[49:0]};
    
  // generate
  //   for (n=0; n< NEUR_RAM_WIDTH / 8 + 1; n= n+1) begin: neur_we_gen
  //       assign neur_we_byte[n] = neur_we & |neur_mask_new[n*8 +: 8];
  //   end
  // endgenerate

  // assign neur_dout = {neur_dout_new[133:56],neur_dout_new[49:0]};



  BRAM_inst_byte #(
      .NB_COL(20),
      .COL_WIDTH(NEUR_BYTE_WIDTH),
      .RAM_DEPTH(NEUR_RAM_DEPTH),
      .INIT_FILE(NEUR_INIT_FILE)
  ) SRAM_wneur (
      .ADDR(neur_addr),
      .DATA_in (neur_din_new),
      .CLK  (CLK),
      .WE  (neur_we_byte),
      .CS  (neur_cs),
      .RST_reg      (),
      .EN_reg    (),
      .DATA_out(neur_dout_new)
  );

  function integer clogb2;
     input integer depth;
    for (clogb2 = 0; depth > 0; clogb2 = clogb2 + 1) depth = depth >> 1;
  endfunction

endmodule
