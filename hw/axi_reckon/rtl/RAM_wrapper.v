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
    input  wire                                CLKN,
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

  wire [WINP_RAM_WIDTH-1:0] winp_din_masked;
  wire [WREC_RAM_WIDTH-1:0] wrec_din_masked;
  wire [WOUT_RAM_WIDTH-1:0] wout_din_masked;
  wire [NEUR_RAM_WIDTH-1:0] neur_din_masked;

  wire [WINP_RAM_WIDTH-1:0] winp_doutb;
  wire [WREC_RAM_WIDTH-1:0] wrec_doutb;
  wire [WOUT_RAM_WIDTH-1:0] wout_doutb;
  wire [NEUR_RAM_WIDTH-1:0] neur_doutb;

  wire [clogb2(WINP_RAM_DEPTH-1)-1:0] winp_addrb;
  wire [clogb2(WREC_RAM_DEPTH-1)-1:0] wrec_addrb;
  wire [clogb2(WOUT_RAM_DEPTH-1)-1:0] wout_addrb;
  wire [clogb2(NEUR_RAM_DEPTH-1)-1:0] neur_addrb;

  wire winp_csb, wrec_csb, wout_csb, neur_csb;

  assign winp_din_masked = (winp_din & winp_mask) | (winp_doutb & ~winp_mask);
  assign winp_addrb = winp_addr;

  assign wrec_din_masked = (wrec_din & wrec_mask) | (wrec_doutb & ~wrec_mask);
  assign wrec_addrb = wrec_addr;

  assign wout_din_masked = (wout_din & wout_mask) | (wout_doutb & ~wout_mask);
  assign wout_addrb = wout_addr;

  assign neur_din_masked = (neur_din & neur_mask) | (neur_doutb & ~neur_mask);
  assign neur_addrb = neur_addr;

  assign winp_csb = winp_we ? 1'b1 : 1'b0;
  assign wrec_csb = wrec_we ? 1'b1 : 1'b0;
  assign wout_csb = wout_we ? 1'b1 : 1'b0;
  assign neur_csb = neur_we ? 1'b1 : 1'b0;

  BRAM2_inst #(
      .RAM_WIDTH(WINP_RAM_WIDTH),
      .RAM_DEPTH(WINP_RAM_DEPTH),
      //.RAM_PERFORMANCE("LOW_LATENCY"),
      .INIT_FILE(WINP_INIT_FILE)
      //.END_ADD(WINP_END_ADD)
  ) SRAM_winp (
      .ADDRA(winp_addr),
      .ADDRB(winp_addrb),
      .DINA (winp_din_masked),
      .DINB (),
      .CLK  (CLK),
      .CLKN (CLKN),
      .WEA  (winp_we),
      .WEB  (1'b0),
      .CSA  (winp_cs),
      .CSB  (winp_csb),
      .RSTA      (),
      .REGENA    (),
      .RSTB      (),
      .REGENB    (),
      .DOUTA(winp_dout),
      .DOUTB(winp_doutb)
  );

  // Recurrent weights SRAM
  BRAM2_inst #(
      .RAM_WIDTH(WREC_RAM_WIDTH),
      .RAM_DEPTH(WREC_RAM_DEPTH),
      //.RAM_PERFORMANCE("LOW_LATENCY"),
      .INIT_FILE(WREC_INIT_FILE)
      //.END_ADD(WREC_END_ADD)
  ) SRAM_wrec (
      .ADDRA(wrec_addr),
      .ADDRB(wrec_addrb),
      .DINA (wrec_din_masked),
      .DINB (),
      .CLK  (CLK),
      .CLKN (CLKN),
      .WEA  (wrec_we),
      .WEB  (1'b0),
      .CSA  (wrec_cs),
      .CSB  (wrec_csb),
      .RSTA      (),
      .REGENA    (),
      .RSTB      (),
      .REGENB    (),
      .DOUTA(wrec_dout),
      .DOUTB(wrec_doutb)
  );

  // Output weights SRAM
  BRAM2_inst #(
      .RAM_WIDTH(WOUT_RAM_WIDTH),
      .RAM_DEPTH(WOUT_RAM_DEPTH),
      //.RAM_PERFORMANCE("LOW_LATENCY"),
      .INIT_FILE(WOUT_INIT_FILE)
      //.END_ADD(WOUT_END_ADD)
  ) SRAM_wout (
      .ADDRA(wout_addr),
      .ADDRB(wout_addrb),
      .DINA (wout_din_masked),
      .DINB (),
      .CLK  (CLK),
      .CLKN (CLKN),
      .WEA  (wout_we),
      .WEB  (1'b0),
      .CSA  (wout_cs),
      .CSB  (wout_csb),
      .RSTA      (),
      .REGENA    (),
      .RSTB      (),
      .REGENB    (),
      .DOUTA(wout_dout),
      .DOUTB(wout_doutb)
  );

  // Neurons SRAM
  BRAM2_inst #(
      .RAM_WIDTH(NEUR_RAM_WIDTH),
      .RAM_DEPTH(NEUR_RAM_DEPTH),
      //.RAM_PERFORMANCE("LOW_LATENCY"),
      .INIT_FILE(NEUR_INIT_FILE)
      //.END_ADD(NEUR_END_ADD)
  ) SRAM_neur (
      .ADDRA(neur_addr),
      .ADDRB(neur_addrb),
      .DINA (neur_din_masked),
      .DINB (),
      .CLK  (CLK),
      .CLKN (CLKN),
      .WEA  (neur_we),
      .WEB  (1'b0),
      .CSA  (neur_cs),
      .CSB  (neur_csb),
      .RSTA      (),
      .REGENA    (),
      .RSTB      (),
      .REGENB    (),
      .DOUTA(neur_dout),
      .DOUTB(neur_doutb)
  );

  function integer clogb2;
    input integer depth;
    for (clogb2 = 0; depth > 0; clogb2 = clogb2 + 1) depth = depth >> 1;
  endfunction

endmodule
