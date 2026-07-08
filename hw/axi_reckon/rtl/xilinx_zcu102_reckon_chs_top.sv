// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Nicole Narr <narrn@student.ethz.ch>
// Christopher Reinwardt <creinwar@student.ethz.ch>
// Cyril Koenig <cykoenig@iis.ee.ethz.ch>
// Yann Picod <ypicod@ethz.ch>
// Paul Scheffler <paulsc@iis.ee.ethz.ch>

`include "cheshire/typedef.svh"
`include "phy_definitions.svh"

// TODO: Expose more IO: unused SPI CS, Serial Link, etc.

module cheshire_top_xilinx import cheshire_pkg::*; #(
  localparam int unsigned Ddr4CsNWidth = 1,
  localparam int unsigned Ddr4DmDbiNWidth = 8,
  localparam int unsigned Ddr4DqWidth = 64,
  localparam int unsigned Ddr4DqsWidth = 8
)(
  input  logic  sys_clk_p,
  input  logic  sys_clk_n,

`ifdef USE_RESET
  input  logic  sys_reset,
`endif
// `ifdef USE_RESETN
//   input  logic  sys_resetn,
// `endif

// `ifdef USE_SWITCHES
//   input logic       test_mode_i,
//   input logic [1:0] boot_mode_i,
// `endif

`ifdef USE_NUM_LED
  output logic [`USE_NUM_LED-1:0] led_o,
`endif

`ifdef USE_JTAG
  input  logic  jtag_tck_i,
  input  logic  jtag_tms_i,
  input  logic  jtag_tdi_i,
  output logic  jtag_tdo_o,
`ifdef USE_JTAG_TRSTN
  input  logic  jtag_trst_ni,
`endif
`ifdef USE_JTAG_VDDGND
  output logic  jtag_vdd_o,
  output logic  jtag_gnd_o,
`endif
`endif

`ifdef USE_DDR4
  `DDR4_INTF(Ddr4CsNWidth, Ddr4DmDbiNWidth, Ddr4DqWidth, Ddr4DqsWidth)
`endif
`ifdef USE_DDR3
  `DDR3_INTF
`endif

  // output logic  uart_tx_o_cp2108,
  output logic  uart_tx_o_gpio,

  // input  logic  uart_rx_i_cp2108,
  input  logic  uart_rx_i_gpio
);

  logic       vio_reset, vio_boot_mode_sel, vio_uart_sel;
  logic [1:0] boot_mode, vio_boot_mode;

  ///////////////////////
  //  Cheshire Config  //
  ///////////////////////

  import cheshire_pkg::*;

  // Use default config as far as possible
  function automatic cheshire_cfg_t gen_cheshire_xilinx_cfg();
    cheshire_cfg_t ret  = DefaultCfg;
    ret.RtcFreq         = 1000000;
  `ifdef USE_USB
    ret.Usb = 1;
  `else
    ret.Usb = 0;
  `endif
  `ifdef USE_CFG_REGS
    ret.RegExtNumSlv   = 1;
    ret.RegExtNumRules = 1;
    // Mirror the address map of the internal configuration registers.
    // * 256K @ AXI: 0x4000_0000
    // * 4K   @ AXI: 0x4100_0000
    // * 256K @ Reg: 0x4200_0000
    // * 4K   @ Reg: 0x4300_0000
    ret.RegExtRegionIdx   [0] = 0;
    ret.RegExtRegionStart [0] = 32'h4300_0000;
    ret.RegExtRegionEnd   [0] = 32'h4300_1000;
  `endif
  `ifdef USE_VCLIC
    ret.Clic = 1;
    ret.ClicVsclic = 1;
    ret.ClicVsprio = 1;
    ret.ClicNumVsctxts = 4;
    ret.ClicPrioWidth = 1;
  `endif
    ret.BusErr          = 0;
    ret.SerialLink      = 0;
    ret.SpiHost         = 1;
    ret.Vga             = 0;
    ret.I2c             = 0;
    ret.Gpio            = 1;
    ret.AxiExtNumSlv    = 1;
    ret.AddrWidth       = 32;
    ret.AxiDataWidth    = 64;
    ret.AxiUserDefault  = 0;
    // Map external AXI slave 0 (axi_rf via axi_layer) to a 1KB region
    ret.AxiExtNumRules       = 1;
    ret.AxiExtRegionIdx[0]   = 0;
    ret.AxiExtRegionStart[0] = 64'h4400_0000;
    ret.AxiExtRegionEnd[0]   = 64'h4400_0400; // +1KB (0x400), end-exclusive
    //ret.AxiUserAmoMsb     = 0;  // MSB of AMO field
    //ret.AxiUserAmoLsb     = 1;
    return ret;
  endfunction

  // Configure cheshire for FPGA mapping
  localparam cheshire_cfg_t FPGACfg = gen_cheshire_xilinx_cfg();
  `CHESHIRE_TYPEDEF_ALL(, FPGACfg)

  ////////////////////////
  //  Clock Generation  in the MPSoC//
  ////////////////////////


  /////////////////////
  //  System Inputs  //
  /////////////////////

//   // Select SoC reset
// `ifdef USE_RESET
//   logic sys_resetn;
//   assign sys_resetn = ~sys_reset;
// `elsif USE_RESETN
//   logic sys_reset;
//   assign sys_reset  = ~sys_resetn;
// `endif

  // Tie off inputs of no switches
`ifndef USE_SWITCHES
  logic       test_mode_i;
  logic [1:0] boot_mode_i;
  assign test_mode_i = '0;
  assign boot_mode_i = '0;
`endif

  ////////////
  //  JTAG  //
  ////////////

`ifdef USE_JTAG_VDDGND
  assign jtag_vdd_o = 1'b1;
  assign jtag_gnd_o = 1'b0;
`endif
`ifndef USE_JTAG_TRSTN
  logic jtag_trst_ni;
  assign jtag_trst_ni = 1'b1;
`endif

  //////////////////////////
  // Internal SPI slave   //
  //////////////////////////

  (* dont_touch = "yes" *) (* mark_debug = "true" *) logic       spi_sck_soc;
  (* dont_touch = "yes" *) (* mark_debug = "true" *) logic [1:0] spi_cs_soc;
  (* dont_touch = "yes" *) (* mark_debug = "true" *) logic [3:0] spi_sd_soc_out;
  (* dont_touch = "yes" *) (* mark_debug = "true" *) logic [3:0] spi_sd_soc_in;

  logic       spi_sck_en;
  logic [1:0] spi_cs_en;
  logic [3:0] spi_sd_en;

  logic reckon_spi_miso;

  assign spi_sd_soc_in[0] = 1'b0;
  assign spi_sd_soc_in[1] = reckon_spi_miso;
  assign spi_sd_soc_in[2] = 1'b0;
  assign spi_sd_soc_in[3] = 1'b0;

// `ifdef USE_STARTUPE3
//   STARTUPE3 #(
//     .PROG_USR("FALSE"),
//     .SIM_CCLK_FREQ(0.0)
//   ) i_startupe3 (
//     .CFGCLK     ( ),
//     .CFGMCLK    ( ),
//     .DI         ( qspi_dqi ),
//     .EOS        ( ),
//     .PREQ       ( ),
//     .DO         ( qspi_dqo ),
//     .DTS        ( qspi_dqo_ts ),
//     .FCSBO      ( qspi_cs_b[1] ),
//     .FCSBTS     ( qspi_cs_b_ts[1] ),
//     .GSR        ( 1'b0 ),
//     .GTS        ( 1'b0 ),
//     .KEYCLEARB  ( 1'b1 ),
//     .PACK       ( 1'b0 ),
//     .USRCCLKO   ( qspi_clk ),
//     .USRCCLKTS  ( qspi_clk_ts ),
//     .USRDONEO   ( 1'b1 ),
//     .USRDONETS  ( 1'b1 )
//   );
// `else
// `ifdef USE_STARTUPE2
//   (*keep="TRUE"*)
//   STARTUPE2 #(
//     .PROG_USR("FALSE"),
//     .SIM_CCLK_FREQ(0.0)
//     ) i_startupe2 (
//     .CFGCLK     ( ),
//     .CFGMCLK    ( ),
//     .EOS        ( ),
//     .PREQ       ( ),
//     .CLK        ( 1'b0 ),
//     .GSR        ( 1'b0 ),
//     .GTS        ( 1'b0 ),
//     .KEYCLEARB  ( 1'b0 ),
//     .PACK       ( 1'b0 ),
//     .USRCCLKO   ( spi_sck_soc ),
//     .USRCCLKTS  ( 1'b0 ),
//     .USRDONEO   ( 1'b0 ),
//     .USRDONETS  ( 1'b0 )
//   );
// `else
  // IOBUF #(
  //   .DRIVE        ( 12        ),
  //   .IBUF_LOW_PWR ( "FALSE"   ),
  //   .IOSTANDARD   ( "DEFAULT" ),
  //   .SLEW         ( "FAST"    )
  // ) i_spih_sck_iobuf (
  //   .O  (  ),
  //   .IO ( spih_sck_o  ),
  //   .I  ( spi_sck_soc ),
  //   .T  ( ~spi_sck_en )
  // );
// `endif

//   IOBUF #(
//     .DRIVE        ( 12        ),
//     .IBUF_LOW_PWR ( "FALSE"   ),
//     .IOSTANDARD   ( "DEFAULT" ),
//     .SLEW         ( "FAST"    )
//   ) i_spih_csb_iobuf (
//     .O  (  ),
//     .IO ( spih_csb_o ),
//     .I  ( spi_cs_soc [1] ),
//     .T  ( ~spi_cs_en [1] )
//   );

//   for (genvar i = 0; i < 4; ++i) begin : gen_qspi_iobufs
//     IOBUF #(
//       .DRIVE        ( 12        ),
//       .IBUF_LOW_PWR ( "FALSE"   ),
//       .IOSTANDARD   ( "DEFAULT" ),
//       .SLEW         ( "FAST"    )
//     ) i_spih_sd_iobuf (
//       .O  ( spi_sd_spih_in [i] ),
//       .IO ( spih_sd_io     [i] ),
//       .I  ( spi_sd_soc_out [i] ),
//       .T  ( ~spi_sd_en     [i] )
//     );
//   end
// `endif
// `endif

  //////////////////
  // I2C Adaption //
  //////////////////

  logic i2c_sda_soc_out;
  logic i2c_sda_soc_in;
  logic i2c_scl_soc_out;
  logic i2c_scl_soc_in;
  logic i2c_sda_en;
  logic i2c_scl_en;

  // Leave I2C bus floating / not connected:
  // from Cheshire point of view, the bus stays idle-high.
  assign i2c_sda_soc_in = 1'b1;
  assign i2c_scl_soc_in = 1'b1;

  /////////////////////////
  // "RTC" Clock Divider //
  /////////////////////////

  logic rtc_clk_d, rtc_clk_q;
  logic [15:0] counter_d, counter_q;

  // Divide soc_clk (50 MHz) by 50 => 1 MHz RTC Clock
  always_comb begin
    counter_d = counter_q + 1;
    rtc_clk_d = rtc_clk_q;

    if(counter_q == 24) begin
      counter_d = '0;
      rtc_clk_d = ~rtc_clk_q;
    end
  end

  always_ff @(posedge soc_clk, posedge sys_rst[0]) begin
    if(sys_rst[0]) begin
      counter_q <= '0;
      rtc_clk_q <= 0;
    end else begin
      counter_q <= counter_d;
      rtc_clk_q <= rtc_clk_d;
    end
  end

  //////////////
  // DRAM MIG //
  //////////////

  axi_llc_req_t axi_llc_mst_req, axi_dram_mst_req;
  axi_llc_rsp_t axi_llc_mst_rsp, axi_dram_mst_rsp;

`ifdef USE_DDR
  dram_wrapper_xilinx #(
    .axi_soc_aw_chan_t ( axi_llc_aw_chan_t ),
    .axi_soc_w_chan_t  ( axi_llc_w_chan_t  ),
    .axi_soc_b_chan_t  ( axi_llc_b_chan_t  ),
    .axi_soc_ar_chan_t ( axi_llc_ar_chan_t ),
    .axi_soc_r_chan_t  ( axi_llc_r_chan_t  ),
    .axi_soc_req_t     ( axi_llc_req_t     ),
    .axi_soc_resp_t    ( axi_llc_rsp_t     ),
    .Ddr4CsNWidth      ( Ddr4CsNWidth      ),
    .Ddr4DmDbiNWidth   ( Ddr4DmDbiNWidth   ),
    .Ddr4DqWidth       ( Ddr4DqWidth       ),
    .Ddr4DqsWidth      ( Ddr4DqsWidth      )
  ) i_dram_wrapper (
    .sys_rst_i    ( sys_rst[0] ),
    .soc_resetn_i ( sys_rstn[0] ),
    .soc_clk_i    ( soc_clk ),
    .dram_clk_i   ( sys_clk ),
    .soc_req_i    ( axi_dram_mst_req ),
    .soc_rsp_o    ( axi_dram_mst_rsp ),
    .*
  );
`endif
  
  ////////////////
  // DRAM Delay //
  ////////////////

`ifdef USE_RAM_DELAY
  axi_fifo_delay_dyn #(
    .aw_chan_t  ( axi_llc_aw_chan_t ),
    .w_chan_t   ( axi_llc_w_chan_t  ),
    .b_chan_t   ( axi_llc_b_chan_t  ),
    .ar_chan_t  ( axi_llc_ar_chan_t ),
    .r_chan_t   ( axi_llc_r_chan_t  ),
    .axi_req_t  ( axi_llc_req_t     ),
    .axi_resp_t ( axi_llc_rsp_t     ),
    .DepthAR    ( 32 ), // Power of two
    .DepthAW    ( 32 ), // Power of two
    .DepthR     ( 32 ), // Power of two
    .DepthW     ( 32 ), // Power of two
    .DepthB     ( 32 ), // Power of two
    .MaxDelay   ( 2**15-1 ) // This is a bit backwards, but defines 16-bit delay timers.
  ) i_axi_fifo_delay_dyn (
    .clk_i      ( soc_clk ),
    .rst_ni     ( sys_rstn[0]   ),
    .aw_delay_i ( reg2hw.dram_aw_delay ),
    .w_delay_i  ( reg2hw.dram_w_delay  ),
    .b_delay_i  ( reg2hw.dram_b_delay  ),
    .ar_delay_i ( reg2hw.dram_ar_delay ),
    .r_delay_i  ( reg2hw.dram_r_delay  ),
    .slv_req_i  ( axi_llc_mst_req ),
    .slv_resp_o ( axi_llc_mst_rsp ),
    .mst_req_o  ( axi_dram_mst_req ),
    .mst_resp_i ( axi_dram_mst_rsp )
  );
`else
  assign axi_dram_mst_req = axi_llc_mst_req;
  assign axi_llc_mst_rsp  = axi_dram_mst_rsp;
`endif

  logic sys_clk;
  logic soc_clk;

  //////////////////
  // Cheshire SoC //
  //////////////////

  (* dont_touch = "yes" *) (* mark_debug = "true" *) axi_slv_req_t [(FPGACfg.AxiExtNumSlv-1):0] axi_slv_i;
  (* dont_touch = "yes" *) (* mark_debug = "true" *) axi_slv_rsp_t [(FPGACfg.AxiExtNumSlv-1):0] axi_slv_o;

  cheshire_soc #(
    .Cfg                ( FPGACfg ),
    .ExtHartinfo        ( '0 ),
    .axi_ext_llc_req_t  ( axi_llc_req_t ),
    .axi_ext_llc_rsp_t  ( axi_llc_rsp_t ),
    .axi_ext_mst_req_t  ( axi_mst_req_t ),
    .axi_ext_mst_rsp_t  ( axi_mst_rsp_t ),
    .axi_ext_slv_req_t  ( axi_slv_req_t ),
    .axi_ext_slv_rsp_t  ( axi_slv_rsp_t ),
    .reg_ext_req_t      ( reg_req_t ),
    .reg_ext_rsp_t      ( reg_rsp_t )
  ) i_cheshire_soc (
    .clk_i              ( soc_clk ),
    .rst_ni             ( sys_rstn[0]   ),
    .test_mode_i        ( test_mode_i ),
    .boot_mode_i        ( boot_mode   ),
    .rtc_i              ( rtc_clk_q       ),
    .axi_llc_mst_req_o  ( axi_llc_mst_req ),
    .axi_llc_mst_rsp_i  ( axi_llc_mst_rsp ),
    .axi_ext_mst_req_i  ( '0 ),
    .axi_ext_mst_rsp_o  ( ),
    .axi_ext_slv_req_o  ( axi_slv_i ),
    .axi_ext_slv_rsp_i  ( axi_slv_o ),
`ifdef USE_CFG_REGS
    .reg_ext_slv_req_o  ( cfg_reg_req ),
    .reg_ext_slv_rsp_i  ( cfg_reg_rsp ),
`else
    .reg_ext_slv_req_o  ( ),
    .reg_ext_slv_rsp_i  ( '0 ),
`endif
    .intr_ext_i         ( '0 ),
    .intr_ext_o         ( ),
    .xeip_ext_o         ( ),
    .mtip_ext_o         ( ),
    .msip_ext_o         ( ),
    .dbg_active_o       ( ),
    .dbg_ext_req_o      ( ),
    .dbg_ext_unavail_i  ( '0 ),
    .slink_rcv_clk_i    ( 1'b1 ),
    .slink_rcv_clk_o    ( ),
    .slink_i            ( '0 ),
    .slink_o            ( ),
`ifdef USE_JTAG
    .jtag_tck_i,
    .jtag_trst_ni,
    .jtag_tms_i,
    .jtag_tdi_i,
    .jtag_tdo_o,
    // TODO: connect to the tdo pad
    .jtag_tdo_oe_o      ( ),
`endif
    .i2c_sda_o          ( i2c_sda_soc_out ),
    .i2c_sda_i          ( i2c_sda_soc_in  ),
    .i2c_sda_en_o       ( i2c_sda_en      ),
    .i2c_scl_o          ( i2c_scl_soc_out ),
    .i2c_scl_i          ( i2c_scl_soc_in  ),
    .i2c_scl_en_o       ( i2c_scl_en      ),
    .spih_sck_o         ( spi_sck_soc     ),
    .spih_sck_en_o      ( spi_sck_en      ),
    .spih_csb_o         ( spi_cs_soc      ),
    .spih_csb_en_o      ( spi_cs_en       ),
    .spih_sd_o          ( spi_sd_soc_out  ),
    .spih_sd_en_o       ( spi_sd_en       ),
    .spih_sd_i          ( spi_sd_soc_in   ),
`ifdef USE_VGA
    .vga_hsync_o,
    .vga_vsync_o,
    .vga_red_o,
    .vga_green_o,
    .vga_blue_o,
`endif
    .uart_tx_o,
    .uart_rx_i, 
    .usb_clk_i          ( 1'b0 ), // Not using USB, tie off to avoid undriven input
    .usb_rst_ni         (  ), // Technically should sync to `usb_clk`, but pulse is long enough
    .usb_dm_i (),
    .usb_dm_o (),
    .usb_dm_oe_o (),
    .usb_dp_i (),
    .usb_dp_o (),
    .usb_dp_oe_o ()
  );

  logic clk15;
  logic SPI_EN_CONF;
  logic [31:0] axi_batch_size, axi_n_samples, axi_do_eprop, axi_n_epochs, infer_count;
  logic [11:0] infer_count_12b;
  
  logic [31:0] reckon_ctrl_i [3:0];
  logic [31:0] reckon_ctrl_o [1:0];
  
  logic [17:0] AERAM_addr;
  logic        AERAM_clk;
  logic [31:0] AERAM_din;
  logic [31:0] AERAM_dout;
  logic        AERAM_cs;
  logic        AERAM_rst;
  logic [3:0]  AERAM_we;

  localparam AxiRegsNin  = 4;
  localparam AxiRegsNout = 8;
  localparam UseAxiGPIO  = 1;

  logic [31:0] axi_reg_o [AxiRegsNout-1:0];
  logic [31:0] axi_reg_i [AxiRegsNin-1:0 ];

  logic debug_axi;

  assign axi_batch_size   = axi_reg_o[0];
  assign axi_n_samples    = axi_reg_o[2];
  assign axi_n_epochs     = axi_reg_o[1];
  assign axi_do_eprop     = axi_reg_o[3];
  assign reckon_ctrl_i[0] = axi_reg_o[4];
  assign reckon_ctrl_i[1] = axi_reg_o[5];
  assign reckon_ctrl_i[2] = axi_reg_o[6];
  assign reckon_ctrl_i[3] = axi_reg_o[7];

  assign debug_axi        = |axi_do_eprop;
  assign led_o[0]         = debug_axi;

  assign axi_reg_i[0]   = {20'h0, infer_count_12b};
  assign axi_reg_i[1]   = reckon_ctrl_o[0];
  assign axi_reg_i[2]   = reckon_ctrl_o[1];
  assign axi_reg_i[3]   = 32'hcafebabe;

  localparam P_TRAIN_DS = `TRAIN_DS;
  localparam P_VAL_DS   = `VAL_DS;

  reckon_axi_top #(
    .ADDR_WIDTH(16),
    .TRAIN_DS_PATH(P_TRAIN_DS),
    .VAL_DS_PATH(P_VAL_DS)
  ) reckon_axi_top_0 (
    .clk_i           ( clk15             ),
    .rst_i           ( sys_rst[1]        ),
    .SPI_EN_CONF     ( SPI_EN_CONF       ),

    .reckon_ctrl_i_0 ( reckon_ctrl_i[0]  ),
    .reckon_ctrl_i_1 ( reckon_ctrl_i[1]  ),
    .reckon_ctrl_i_2 ( reckon_ctrl_i[2]  ),
    .reckon_ctrl_i_3 ( reckon_ctrl_i[3]  ),
    .reckon_ctrl_o_0 ( reckon_ctrl_o[0]  ),
    .reckon_ctrl_o_1 ( reckon_ctrl_o[1]  ),

    .spi_sck_wire    ( spi_sck_soc       ),
    .spi_mosi_wire   ( spi_sd_soc_out[0] ),
    .spi_miso_wire   ( reckon_spi_miso   ),
    .spi_cs_wire     ( spi_cs_soc[0]     ),

    .BRAM_PORTA_addr ( AERAM_addr        ),
    .BRAM_PORTA_clk  ( AERAM_clk         ),
    .BRAM_PORTA_din  ( AERAM_din         ),
    .BRAM_PORTA_en   ( AERAM_cs          ),
    .BRAM_PORTA_rst  ( AERAM_rst         ),
    .BRAM_PORTA_we   ( AERAM_we          ),
    .BRAM_PORTA_dout ( AERAM_dout        ),

    .infer_count_o   ( infer_count_12b    ),
    .batch_size_i    ( axi_batch_size[11:0] ),
    .n_samples_i     ( axi_n_samples[11:0]  ),
    .n_epochs_i      ( axi_n_epochs[11:0]   ),
    .do_eprop_i      ( axi_do_eprop[2:0]    ),

    .cycles_counter_0(cycles_counter[0]),
    .cycles_counter_1(cycles_counter[1]),
    .cycles_counter_2(cycles_counter[2]),
    .cycles_counter_3(cycles_counter[3]),
    .cycles_counter_4(cycles_counter[4]),
    .cycles_counter_5(cycles_counter[5]),
    .cycles_counter_6(cycles_counter[6]),
    .cycles_counter_7(cycles_counter[7]),

    .counter_config_0(counter_config[0]),
    .counter_config_1(counter_config[1]),
    .counter_config_2(counter_config[2]),
    .counter_config_3(counter_config[3]),
    .counter_config_4(counter_config[4]),
    .counter_config_5(counter_config[5]),
    .counter_config_6(counter_config[6]),
    .counter_config_7(counter_config[7])
  );

  wire [31:0] cycles_counter [7:0];
  wire [31:0] counter_config [7:0];

  axi_layer #(
    .Cfg               ( FPGACfg ),
    .AxiRegsNin        ( AxiRegsNin ),
    .AxiRegsNout       ( AxiRegsNout ),
    .UseAxiGPIO        ( UseAxiGPIO ),
    .axi_ext_slv_req_t ( axi_slv_req_t ),
    .axi_ext_slv_rsp_t ( axi_slv_rsp_t )
  ) axi_layer_0 (
    .clk_i             ( soc_clk ),
    .rst_ni            ( sys_rstn[0] ),
    .slv_req           ( axi_slv_i ),
    .slv_rsp           ( axi_slv_o ),
    .axi_reg_o         ( axi_reg_o ),
    .axi_reg_i         ( axi_reg_i ),
    .axi_gpio_o        ( ),
    .axi_gpio_i        ( '0 ),
    .cycles_counter(cycles_counter),
    .counter_config(counter_config)
  );

  //////////////////
  //  Reset Sync  //
  //////////////////

  logic [1:0] rst_dbg;
  logic [1:0] rst_reg [1:0];
  (* ASYNC_REG = "TRUE" *) reg [1:0] rst_sync1, rst_sync2, sys_rst, sys_rstn;

///////////// rst_reg[0] is for soc_clk domain, rst_reg[1] is for clk15 domain.

  (* ASYNC_REG = "TRUE" *)
  always_ff @(posedge soc_clk or posedge vio_reset or posedge sys_reset) begin
      if (vio_reset || sys_reset) begin
          rst_reg[0] <= 2'b11; // Active high reset
      end else begin
          rst_sync1[0] <= rst_reg[0][0];
          rst_sync2[0] <= rst_sync1[0];
          sys_rstn[0]  <= ~rst_sync2[0];
          sys_rst[0]   <= rst_sync2[0];
          rst_reg[0]   <= 2'b00;
      end
  end

  (* ASYNC_REG = "TRUE" *)
  always_ff @(posedge clk15 or posedge vio_reset or posedge sys_reset) begin
      if (vio_reset || sys_reset) begin
          rst_reg[1] <= 2'b11; // Active high reset
      end else if (clk15) begin
          rst_sync1[1] <= rst_reg[1][0];
          rst_sync2[1] <= rst_sync1[1];
          sys_rstn[1]  <= ~rst_sync2[1];
          sys_rst[1]   <= rst_sync2[1];
          rst_reg[1]   <= 2'b00;
      end
  end

  assign rst_dbg[0] = sys_rst[0];
  assign rst_dbg[1] = sys_rst[1];
  logic uart_tx_o, uart_rx_i;

  // assign sys_rst = sys_reset | vio_reset;
  // assign sys_rst = vio_reset;

  assign boot_mode = vio_boot_mode_sel ? vio_boot_mode : boot_mode_i;

  // assign uart_tx_o_cp2108 = vio_uart_sel ? uart_tx_o : '0;
  // assign uart_tx_o_gpio   = vio_uart_sel ? '0 : uart_tx_o;
  // assign uart_rx_i        = vio_uart_sel ? uart_rx_i_cp2108 : uart_rx_i_gpio;

  assign uart_tx_o_gpio   = uart_tx_o;
  assign uart_rx_i        = uart_rx_i_gpio;

  wire clk_buf_n, clk_buf_p;

  logic [25:0] cnt_led;
  always_ff @(posedge soc_clk) begin
    cnt_led <= cnt_led + 1;
    led_o[1] <= cnt_led == 26'd25000000 ? ~led_o[1] : led_o[1];
    if (cnt_led == 26'd25000000) begin
      cnt_led <= 0;
    end
  end

// IBUFDS_DIFF_OUT #(
//   .DIFF_TERM("TRUE"),   // Differential Termination, "TRUE"/"FALSE"
//   .IBUF_LOW_PWR("FALSE"), // Low power="TRUE", Highest performance="FALSE"
//   .IOSTANDARD("LVDS_25") // Specify the input I/O standard
// ) IBUFDS_DIFF_OUT_inst (
//   .O(clk_buf_p),   // Buffer diff_p output
//   .OB(clk_buf_n), // Buffer diff_n output
//   .I(sys_clk_p),   // Diff_p buffer input (connect directly to top-level port)
//   .IB(sys_clk_n)  // Diff_n buffer input (connect directly to top-level port)
// );

IBUFDS #(
  .IBUF_LOW_PWR ("FALSE")
) i_bufds_sys_clk (
  .I  ( sys_clk_p ),
  .IB ( sys_clk_n ),
  .O  ( sys_clk   )
);

`ifdef USE_MPSOC
  zcu102_mpsoc_wrapper MPSoC_controller_0 (
    .BRAM_PORTA_addr(AERAM_addr),
    .BRAM_PORTA_clk (AERAM_clk),
    .BRAM_PORTA_din (AERAM_din),
    .BRAM_PORTA_en  (AERAM_cs),
    .BRAM_PORTA_rst (AERAM_rst),
    .BRAM_PORTA_we  (AERAM_we),
    .BRAM_PORTA_dout(AERAM_dout),
    .CLK_IN1_D_clk_n(sys_clk_n),
    .CLK_IN1_D_clk_p(sys_clk_p),
  `ifdef USE_VIO
    .probe_out0 ( vio_reset         ),
    .probe_out1 ( vio_boot_mode     ),
    .probe_out2 ( vio_boot_mode_sel ),
    .probe_out3 ( vio_uart_sel  ),
    .probe_in0  ( SPI_EN_CONF   ),
    .probe_in1  ( debug_axi     ),
`endif
    .clk_50   ( soc_clk  ),
    .clk_15   ( clk15)
  );
`else

  assign AERAM_addr = 18'b0;
  assign AERAM_clk  = 1'b0;
  assign AERAM_cs   = 1'b0;
  assign AERAM_din  = 1'b0;
  assign AERAM_we   = 4'b0;
  assign AERAM_rst  = 1'b0;

  clkwiz i_clkwiz (
    // .clk_in1_n(sys_clk_n),
    .clk_in1(sys_clk),
    .clk_50   ( soc_clk  ),
    .clk_15   ( clk15)
  );
  `ifdef USE_VIO
    vio i_vio (
      .clk        ( soc_clk ),
      .probe_out0 ( vio_reset         ),
      .probe_out1 ( vio_boot_mode     ),
      .probe_out2 ( vio_boot_mode_sel ),
      .probe_out3 ( vio_uart_sel  ),
      .probe_in0  ( SPI_EN_CONF   )
    );

  `else
    assign vio_reset          = '0;
    assign vio_boot_mode      = 2'h2;
    assign vio_boot_mode_sel  = 1'b1;
    assign vio_uart_sel       = '0;
  `endif
`endif

endmodule
