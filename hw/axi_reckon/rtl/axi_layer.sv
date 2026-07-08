`include "cheshire/typedef.svh"
`include "include/axi_macros.svh"
`include "axi-rt/assign.svh"
`include "axi-rt/port.svh"
`include "axi/typedef.svh"
`define AXI_TYPEDEF_SVH_

module axi_layer import cheshire_pkg::*; #
(
  parameter cheshire_cfg_t Cfg = '0,
  parameter int unsigned AxiRegsNin  = 32,
  parameter int unsigned AxiRegsNout = 8,
  parameter type axi_ext_slv_req_t  = logic,
  parameter type axi_ext_slv_rsp_t  = logic,
  parameter int UseAxiGPIO = 1
)(
  input  logic clk_i,
  input  logic rst_ni,
  // use the canonical Cheshire packed AXI types on the module ports
  input  axi_ext_slv_req_t  [(Cfg.AxiExtNumSlv-1):0] slv_req,
  output axi_ext_slv_rsp_t  [(Cfg.AxiExtNumSlv-1):0] slv_rsp,

  output logic [31:0] axi_reg_o [AxiRegsNout-1:0],
  input  logic [31:0] axi_reg_i [AxiRegsNin-1:0],
  output logic [31:0] axi_gpio_o,
  input  logic [31:0] axi_gpio_i,

  input wire [31:0]  cycles_counter [7:0],

  output wire [31:0] counter_config [7:0]
);

  localparam N1 = AxiRegsNin  == 0 ? 1 : AxiRegsNin;
  localparam N2 = AxiRegsNout == 0 ? 1 : AxiRegsNout;

  // clock / reset locals
  logic axi_aclk;
  logic axi_aresetn;

  logic [Cfg.AddrWidth+2-1 : 0]       s_axi_lite_rf_awaddr_i;
  logic [2 : 0] 						          s_axi_lite_rf_awprot_i;
  logic  								              s_axi_lite_rf_awvalid_i;
  logic  								              s_axi_lite_rf_awready_o;
  logic [Cfg.AxiDataWidth-1 : 0]      s_axi_lite_rf_wdata_i;
  logic [(Cfg.AxiDataWidth/8)-1 : 0] 	s_axi_lite_rf_wstrb_i;
  logic  								              s_axi_lite_rf_wvalid_i;
  logic  								              s_axi_lite_rf_wready_o;
  logic [1 : 0] 						          s_axi_lite_rf_bresp_o;
  logic  								              s_axi_lite_rf_bvalid_o;
  logic  								              s_axi_lite_rf_bready_i;
  logic [Cfg.AddrWidth-1 : 0]     		s_axi_lite_rf_araddr_i;
  logic [2 : 0] 						          s_axi_lite_rf_arprot_i;
  logic  								              s_axi_lite_rf_arvalid_i;
  logic  								              s_axi_lite_rf_arready_o;
  logic [Cfg.AxiDataWidth-1 : 0] 		  s_axi_lite_rf_rdata_o;
  logic [1 : 0] 						          s_axi_lite_rf_rresp_o;
  logic  								              s_axi_lite_rf_rvalid_o;
  logic  								              s_axi_lite_rf_rready_i;

  `CHESHIRE_TYPEDEF_ALL(, Cfg)
  `AXI_LITE_TYPEDEF_ALL(axirf_lite, addr_t, axi_data_t, axi_strb_t)

  axirf_lite_req_t axi_slv_rf_i;
  axirf_lite_resp_t axi_slv_rf_o;

  // `AXI_LITE_S(axi_lite_rf, addr_t, axi_data_t, axi_strb_t)
  `AXI_LITE_ASSIGN_SLAVE_TO_FLAT_ARRAY (rf, 1, axi_slv_rf_i, axi_slv_rf_o)

// `define AXI_LITE_ASSIGN_SLAVE_TO_FLAT_ARRAY(pat, __width, req, rsp) \
//   assign req.aw_valid  = s_axi_lite_``pat``_awvalid_i  ;            \

  axi_ext_slv_req_t full_axi_rf_req;
  axi_ext_slv_rsp_t full_axi_rf_rsp;

  // --- External slave array -> single RF instance adapter (index 0 chosen here) ---
  // If multiple external slaves are present adapt this accordingly.
  generate
    if (Cfg.AxiExtNumSlv > 0) begin
      // connect first external slave to the RF adapter
      assign full_axi_rf_req = slv_req[0];
      assign slv_rsp[0] = full_axi_rf_rsp;
    end else begin
      // tie off if none present
      assign full_axi_rf_req = '0;
    end
  endgenerate

  // small register arrays used by the AXI4 RF slave IP
  logic [31:0] in_reg  [0:31];
  logic [31:0] out_reg [0:7];
  logic [31:0] gpio_o;
  logic [31:0] gpio_i;

  // map external arrays to local regs
  genvar i;
  generate
    for (i = 0; i < 32; i = i + 1) begin : GEN_IN_REGS
      assign in_reg[i] = axi_reg_i[i];
    end
    for (i = 0; i < 8; i = i + 1) begin : GEN_OUT_REGS
      assign axi_reg_o[i] = out_reg[i];
    end
  endgenerate

  // AXI clock and reset
  assign axi_aclk    = clk_i;
  assign axi_aresetn = rst_ni;

  localparam axi_in_t AxiIn = gen_axi_in(Cfg);
  localparam int unsigned AxiSlvIdWidth = Cfg.AxiMstIdWidth + $clog2(AxiIn.num_in);

  axi_to_axi_lite #(
    .AxiAddrWidth    ( Cfg.AddrWidth     ),
    .AxiDataWidth    ( Cfg.AxiDataWidth  ),
    .AxiIdWidth      (   AxiSlvIdWidth   ),
    .AxiUserWidth    ( Cfg.AxiUserWidth  ),
    .AxiMaxWriteTxns ( 4 ),
    .AxiMaxReadTxns  ( 4 ),
    .FallThrough     ( 1 ),
    .FullBW          ( 0 ),
    .full_req_t      ( axi_ext_slv_req_t ),
    .full_resp_t     ( axi_ext_slv_rsp_t ),
    .lite_req_t      ( axirf_lite_req_t  ),
    .lite_resp_t     ( axirf_lite_resp_t )
  ) i_axi_to_axi_lite_rf (
    .clk_i      ( clk_i      ),
    .rst_ni     ( rst_ni     ),
    .test_i     ( 1'b0       ),
    // slave port full AXI4+ATOP (packed)
    .slv_req_i  ( full_axi_rf_req   ),
    .slv_resp_o ( full_axi_rf_rsp  ),
    // master port AXI4-Lite (packed)
    .mst_req_o  ( axi_slv_rf_i  ),
    .mst_resp_i ( axi_slv_rf_o  )
  );

  logic [31:0] axilite32_rdata, axilite32_wdata, axilite32_raddr, axilite32_waddr, tmp_axilite32_raddr, tmp_axilite32_waddr;

  assign tmp_axilite32_raddr = axi_slv_rf_i.ar.addr - Cfg.AxiExtRegionStart[0];
  assign tmp_axilite32_waddr = axi_slv_rf_i.aw.addr - Cfg.AxiExtRegionStart[0];

  // assign s_axi_lite_rf_rdata_o = {32'b0, axilite32_rdata};
  assign axi_slv_rf_o.r.data = {32'b0, axilite32_rdata};
  assign axilite32_wdata = axi_slv_rf_i.w.data[31:0];
  assign axilite32_waddr = {3'b0, tmp_axilite32_waddr[31:3]};
  assign axilite32_raddr = {3'b0, tmp_axilite32_raddr[31:3]};

  // Instantiate the AXI4 RF slave IP (AXI-Lite frontend)
  AXI4_RF_slave_lite_v1_0_S00_AXI # (
    .N1(N1),
    .N2(N2),
    .C_S_AXI_DATA_WIDTH(32),
    .C_S_AXI_ADDR_WIDTH(Cfg.AddrWidth)
  ) AXI4_RF_slave_lite_v1_0_S00_AXI_inst (
    .S_AXI_ACLK   (axi_aclk),
    .S_AXI_ARESETN(axi_aresetn),

    .S_AXI_AWADDR (axilite32_waddr),
    .S_AXI_AWPROT (axi_slv_rf_i.aw.prot),
    .S_AXI_AWVALID(axi_slv_rf_i.aw_valid),
    .S_AXI_AWREADY(axi_slv_rf_o.aw_ready),

    .S_AXI_WDATA  (axilite32_wdata),
    .S_AXI_WSTRB  (axi_slv_rf_i.w.strb),
    .S_AXI_WVALID (axi_slv_rf_i.w_valid),
    .S_AXI_WREADY (axi_slv_rf_o.w_ready),

    .S_AXI_BRESP  (axi_slv_rf_o.b.resp),
    .S_AXI_BVALID (axi_slv_rf_o.b_valid),
    .S_AXI_BREADY (axi_slv_rf_i.b_ready),

    .S_AXI_ARADDR (axilite32_raddr),
    .S_AXI_ARPROT (axi_slv_rf_i.ar.prot),
    .S_AXI_ARVALID(axi_slv_rf_i.ar_valid),
    .S_AXI_ARREADY(axi_slv_rf_o.ar_ready),

    .S_AXI_RDATA  (axilite32_rdata),
    .S_AXI_RRESP  (axi_slv_rf_o.r.resp),
    .S_AXI_RVALID (axi_slv_rf_o.r_valid),
    .S_AXI_RREADY (axi_slv_rf_i.r_ready),


    // register / GPIO ports
    .in_reg0(in_reg[0]),   .in_reg1(in_reg[1]),   .in_reg2(in_reg[2]),   .in_reg3(in_reg[3]),
    .in_reg4(in_reg[4]),   .in_reg5(in_reg[5]),   .in_reg6(in_reg[6]),   .in_reg7(in_reg[7]),
    .in_reg8(in_reg[8]),   .in_reg9(in_reg[9]),   .in_reg10(in_reg[10]), .in_reg11(in_reg[11]),
    .in_reg12(in_reg[12]), .in_reg13(in_reg[13]), .in_reg14(in_reg[14]), .in_reg15(in_reg[15]),
    .in_reg16(in_reg[16]), .in_reg17(in_reg[17]), .in_reg18(in_reg[18]), .in_reg19(in_reg[19]),
    .in_reg20(in_reg[20]), .in_reg21(in_reg[21]), .in_reg22(in_reg[22]), .in_reg23(in_reg[23]),
    .in_reg24(in_reg[24]), .in_reg25(in_reg[25]), .in_reg26(in_reg[26]), .in_reg27(in_reg[27]),
    .in_reg28(in_reg[28]), .in_reg29(in_reg[29]), .in_reg30(in_reg[30]), .in_reg31(in_reg[31]),

    .cycles_counter_0(cycles_counter[0]), .cycles_counter_1(cycles_counter[1]),
    .cycles_counter_2(cycles_counter[2]), .cycles_counter_3(cycles_counter[3]),
    .cycles_counter_4(cycles_counter[4]), .cycles_counter_5(cycles_counter[5]),
    .cycles_counter_6(cycles_counter[6]), .cycles_counter_7(cycles_counter[7]),

    .out_reg0(out_reg[0]), .out_reg1(out_reg[1]), .out_reg2(out_reg[2]), .out_reg3(out_reg[3]),
    .out_reg4(out_reg[4]), .out_reg5(out_reg[5]), .out_reg6(out_reg[6]), .out_reg7(out_reg[7]),

    .counter_config_0(counter_config[0]), .counter_config_1(counter_config[1]),
    .counter_config_2(counter_config[2]), .counter_config_3(counter_config[3]),
    .counter_config_4(counter_config[4]), .counter_config_5(counter_config[5]),
    .counter_config_6(counter_config[6]), .counter_config_7(counter_config[7]),

    .gpio_o(gpio_o),
    .gpio_i(gpio_i)
  );

  // GPIO / register wiring
  generate
    if (UseAxiGPIO) begin
      assign axi_gpio_o = gpio_o;
      assign gpio_i     = axi_gpio_i;
    end else begin
      assign axi_gpio_o = '0;
      assign gpio_i     = '0;
    end
  endgenerate

endmodule

