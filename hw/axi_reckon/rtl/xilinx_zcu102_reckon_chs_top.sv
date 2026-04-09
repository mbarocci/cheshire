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

// `ifdef USE_I2C
//   inout  wire   i2c_scl_io,
//   inout  wire   i2c_sda_io,
// `endif

// `ifdef USE_SD
//   input  logic        sd_cd_i,
//   output logic        sd_cmd_o,
//   inout  wire  [3:0]  sd_d_io,
//   output logic        sd_reset_o,
//   output logic        sd_sclk_o,
// `endif

// `ifdef USE_FAN
//   input  logic [3:0]  fan_sw,
//   output logic        fan_pwm,
// `endif

// `ifdef USE_VGA
//   // VGA Colour signals
//   output logic        vga_hsync_o,
//   output logic        vga_vsync_o,
//   output logic [4:0]  vga_red_o,
//   output logic [5:0]  vga_green_o,
//   output logic [4:0]  vga_blue_o,
// `endif

`ifdef USE_DDR4
  `DDR4_INTF(Ddr4CsNWidth, Ddr4DmDbiNWidth, Ddr4DqWidth, Ddr4DqsWidth)
`endif
`ifdef USE_DDR3
  `DDR3_INTF
`endif

// `ifdef USE_USB
//   inout  wire [UsbNumPorts-1:0] usb_dm_io,
//   inout  wire [UsbNumPorts-1:0] usb_dp_io,
// `endif

  output logic  uart_tx_o_cp2108,
  output logic  uart_tx_o_gpio,

  input  logic  uart_rx_i_cp2108,
  input  logic  uart_rx_i_gpio
);

  logic       vio_reset, vio_boot_mode_sel, vio_uart_sel;
  logic [1:0] boot_mode, vio_boot_mode;
  logic       sys_rst;

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
  logic [3:0] spi_sd_soc_in;

  logic       spi_sck_en;
  logic [1:0] spi_cs_en;
  logic [3:0] spi_sd_en;

  logic reckon_spi_miso;

  assign spi_sd_soc_in[0] = 1'b0;
  assign spi_sd_soc_in[1] = reckon_spi_miso;
  assign spi_sd_soc_in[2] = 1'b0;
  assign spi_sd_soc_in[3] = 1'b0;

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

  always_ff @(posedge soc_clk, negedge rst_n) begin
    if(~rst_n) begin
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
    .sys_rst_i    ( sys_rst ),
    .soc_resetn_i ( rst_n   ),
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
    .rst_ni     ( rst_n   ),
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
    .rst_ni             ( rst_n   ),
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
    .usb_clk_i          ( usb_clk ),
    .usb_rst_ni         ( rst_n ), // Technically should sync to `usb_clk`, but pulse is long enough
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

  reckon_axi_top #(
    .ADDR_WIDTH(16)
  ) reckon_axi_top_0 (
    .clk_i           ( clk15             ),
    .rst_i           ( ~rst_n            ),
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

    .BRAM_PORTA_addr ( AERAM_add         ),
    .BRAM_PORTA_clk  ( AERAM_clk         ),
    .BRAM_PORTA_din  ( AERAM_din         ),
    .BRAM_PORTA_en   ( AERAM_cs          ),
    .BRAM_PORTA_rst  ( AERAM_rst         ),
    .BRAM_PORTA_we   ( AERAM_we          ),
    .BRAM_PORTA_dout ( AERAM_dout        ),

    .infer_count_o   ( infer_count_12b    ),
    .batch_size_i    ( axi_batch_size[11:0] ),
    .n_samples_i     ( axi_n_samples[11:0]  ),
    .do_eprop_i      ( axi_do_eprop[2:0]    )
  );

  (* dont_touch = "yes" *) (* mark_debug = "true" *) axi_slv_req_t [(FPGACfg.AxiExtNumSlv-1):0] axi_slv_i;
  (* dont_touch = "yes" *) (* mark_debug = "true" *) axi_slv_rsp_t [(FPGACfg.AxiExtNumSlv-1):0] axi_slv_o;

  axi_layer #(
    .Cfg               ( FPGACfg ),
    .AxiRegsNin        ( AxiRegsNin ),
    .AxiRegsNout       ( AxiRegsNout ),
    .UseAxiGPIO        ( UseAxiGPIO ),
    .axi_ext_slv_req_t ( axi_slv_req_t ),
    .axi_ext_slv_rsp_t ( axi_slv_rsp_t )
  ) axi_layer_0 (
    .clk_i             ( soc_clk ),
    .rst_ni            ( rst_n ),
    .slv_req           ( axi_slv_i ),
    .slv_rsp           ( axi_slv_o ),
    .axi_reg_o         ( axi_reg_o ),
    .axi_reg_i         ( axi_reg_i ),
    .axi_gpio_o        ( ),
    .axi_gpio_i        ( '0 )
  );

  //////////////////
  //  Reset Sync  //
  //////////////////

  logic rst_n;

  rstgen i_rstgen (
    .clk_i        ( soc_clk     ),
    .rst_ni       ( ~sys_rst    ),
    .test_mode_i  ( test_mode_i ),
    .rst_no       ( rst_n       ),
    .init_no      ( )
  );

  logic uart_tx_o, uart_rx_i;

`ifdef USE_RESET
  assign sys_rst = sys_reset | vio_reset;
`elsif USE_RESETN
  assign sys_rst = ~sys_resetn | vio_reset;
`endif
  assign boot_mode = vio_boot_mode_sel ? vio_boot_mode : boot_mode_i;

  assign uart_tx_o_cp2108 = vio_uart_sel ? uart_tx_o : '0;
  assign uart_tx_o_gpio   = vio_uart_sel ? '0 : uart_tx_o;
  assign uart_rx_i        = vio_uart_sel ? uart_rx_i_cp2108 : uart_rx_i_gpio;

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
    .clk_48  ( ),
    .clk_50   ( soc_clk  ),
    .clk_20   ( ),
    .clk_15   ( clk15),
    .probe_out0 ( vio_reset         ),
    .probe_out1 ( vio_boot_mode     ),
    .probe_out2 ( vio_boot_mode_sel ),
    .probe_out3 ( vio_uart_sel  ),
    .probe_in0  ( SPI_EN_CONF   ),
    .probe_in1  ( debug_axi     )
  );
`else
  IBUFDS #(
    .IBUF_LOW_PWR ("FALSE")
  ) i_bufds_sys_clk (
    .I  ( sys_clk_p ),
    .IB ( sys_clk_n ),
    .O  ( sys_clk   )
  );

  clkwiz i_clkwiz (
    .clk_in1  ( sys_clk ),
    .reset    ( '0 ),
    .locked   ( ),    
    .clk_48  ( ),
    .clk_50   ( soc_clk  ),
    .clk_20   ( ),
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
    assign vio_boot_mode      = '0;
    assign vio_boot_mode_sel  = '0;
    assign vio_uart_out_sel   = '0;
  `endif
`endif

endmodule
