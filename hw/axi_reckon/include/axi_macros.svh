`ifndef AXI_PORT_FLAT_SVH_
`define AXI_PORT_FLAT_SVH_

`include "axi/port.svh"

// Flat (directionless) AXI signal macros.
// These create signal declarations like the port macros in axi/port.svh
// but without input/output keywords so they can be used inside a module.

// Full AXI master flat signals
`define AXI_M(__name, __addr_t, __data_t, __strb_t, __id_t, __aw_user_t, __w_user_t, __b_user_t, __ar_user_t, __r_user_t) \
  logic                     m_axi_``__name``_awvalid;   \
  __id_t                    m_axi_``__name``_awid;      \
  __addr_t                  m_axi_``__name``_awaddr;    \
  axi_pkg::len_t            m_axi_``__name``_awlen;     \
  axi_pkg::size_t           m_axi_``__name``_awsize;    \
  axi_pkg::burst_t          m_axi_``__name``_awburst;   \
  logic                     m_axi_``__name``_awlock;    \
  axi_pkg::cache_t          m_axi_``__name``_awcache;   \
  axi_pkg::prot_t           m_axi_``__name``_awprot;    \
  axi_pkg::qos_t            m_axi_``__name``_awqos;     \
  axi_pkg::region_t         m_axi_``__name``_awregion;  \
  __aw_user_t               m_axi_``__name``_awuser;    \
  logic                     m_axi_``__name``_wvalid;    \
  __data_t                  m_axi_``__name``_wdata;     \
  __strb_t                  m_axi_``__name``_wstrb;     \
  logic                     m_axi_``__name``_wlast;     \
  __w_user_t                m_axi_``__name``_wuser;     \
  logic                     m_axi_``__name``_bready;    \
  logic                     m_axi_``__name``_arvalid;   \
  __id_t                    m_axi_``__name``_arid;      \
  __addr_t                  m_axi_``__name``_araddr;    \
  axi_pkg::len_t            m_axi_``__name``_arlen;     \
  axi_pkg::size_t           m_axi_``__name``_arsize;    \
  axi_pkg::burst_t          m_axi_``__name``_arburst;   \
  logic                     m_axi_``__name``_arlock;    \
  axi_pkg::cache_t          m_axi_``__name``_arcache;   \
  axi_pkg::prot_t           m_axi_``__name``_arprot;    \
  axi_pkg::qos_t            m_axi_``__name``_arqos;     \
  axi_pkg::region_t         m_axi_``__name``_arregion;  \
  __ar_user_t               m_axi_``__name``_aruser;    \
  logic                     m_axi_``__name``_rready;    \
  logic                     m_axi_``__name``_awready;   \
  logic                     m_axi_``__name``_arready;   \
  logic                     m_axi_``__name``_wready;    \
  logic                     m_axi_``__name``_bvalid;    \
  __id_t                    m_axi_``__name``_bid;       \
  axi_pkg::resp_t           m_axi_``__name``_bresp;     \
  __b_user_t                m_axi_``__name``_buser;     \
  logic                     m_axi_``__name``_rvalid;    \
  __id_t                    m_axi_``__name``_rid;       \
  __data_t                  m_axi_``__name``_rdata;     \
  axi_pkg::resp_t           m_axi_``__name``_rresp;     \
  logic                     m_axi_``__name``_rlast;     \
  __r_user_t                m_axi_``__name``_ruser;

// Full AXI slave flat signals
`define AXI_S(__name, __addr_t, __data_t, __strb_t, __id_t, __aw_user_t, __w_user_t, __b_user_t, __ar_user_t, __r_user_t) \
  logic                     s_axi_``__name``_awvalid;   \
  __id_t                    s_axi_``__name``_awid;      \
  __addr_t                  s_axi_``__name``_awaddr;    \
  axi_pkg::len_t            s_axi_``__name``_awlen;     \
  axi_pkg::size_t           s_axi_``__name``_awsize;    \
  axi_pkg::burst_t          s_axi_``__name``_awburst;   \
  logic                     s_axi_``__name``_awlock;    \
  axi_pkg::cache_t          s_axi_``__name``_awcache;   \
  axi_pkg::prot_t           s_axi_``__name``_awprot;    \
  axi_pkg::qos_t            s_axi_``__name``_awqos;     \
  axi_pkg::region_t         s_axi_``__name``_awregion;  \
  __aw_user_t               s_axi_``__name``_awuser;    \
  logic                     s_axi_``__name``_wvalid;    \
  __data_t                  s_axi_``__name``_wdata;     \
  __strb_t                  s_axi_``__name``_wstrb;     \
  logic                     s_axi_``__name``_wlast;     \
  __w_user_t                s_axi_``__name``_wuser;     \
  logic                     s_axi_``__name``_bready;    \
  logic                     s_axi_``__name``_arvalid;   \
  __id_t                    s_axi_``__name``_arid;      \
  __addr_t                  s_axi_``__name``_araddr;    \
  axi_pkg::len_t            s_axi_``__name``_arlen;     \
  axi_pkg::size_t           s_axi_``__name``_arsize;    \
  axi_pkg::burst_t          s_axi_``__name``_arburst;   \
  logic                     s_axi_``__name``_arlock;    \
  axi_pkg::cache_t          s_axi_``__name``_arcache;   \
  axi_pkg::prot_t           s_axi_``__name``_arprot;    \
  axi_pkg::qos_t            s_axi_``__name``_arqos;     \
  axi_pkg::region_t         s_axi_``__name``_arregion;  \
  __ar_user_t               s_axi_``__name``_aruser;    \
  logic                     s_axi_``__name``_rready;    \
  logic                     s_axi_``__name``_awready;   \
  logic                     s_axi_``__name``_arready;   \
  logic                     s_axi_``__name``_wready;    \
  logic                     s_axi_``__name``_bvalid;    \
  __id_t                    s_axi_``__name``_bid;       \
  axi_pkg::resp_t           s_axi_``__name``_bresp;     \
  __b_user_t                s_axi_``__name``_buser;     \
  logic                     s_axi_``__name``_rvalid;    \
  __id_t                    s_axi_``__name``_rid;       \
  __data_t                  s_axi_``__name``_rdata;     \
  axi_pkg::resp_t           s_axi_``__name``_rresp;     \
  logic                     s_axi_``__name``_rlast;     \
  __r_user_t                s_axi_``__name``_ruser;

// AXI-Lite master flat signals (no ID, len, size, burst, user)
`define AXI_LITE_M(__name, __addr_t, __data_t, __strb_t) \
  logic                     m_axi_``__name``_awvalid;   \
  __addr_t                  m_axi_``__name``_awaddr;    \
  axi_pkg::prot_t           m_axi_``__name``_awprot;    \
  logic                     m_axi_``__name``_wvalid;    \
  __data_t                  m_axi_``__name``_wdata;     \
  __strb_t                  m_axi_``__name``_wstrb;     \
  logic                     m_axi_``__name``_bready;    \
  logic                     m_axi_``__name``_arvalid;   \
  __addr_t                  m_axi_``__name``_araddr;    \
  axi_pkg::prot_t           m_axi_``__name``_arprot;    \
  logic                     m_axi_``__name``_rready;    \
  logic                     m_axi_``__name``_awready;   \
  logic                     m_axi_``__name``_wready;    \
  logic                     m_axi_``__name``_bvalid;    \
  axi_pkg::resp_t           m_axi_``__name``_bresp;     \
  logic                     m_axi_``__name``_arready;   \
  logic                     m_axi_``__name``_rvalid;    \
  __data_t                  m_axi_``__name``_rdata;     \
  axi_pkg::resp_t           m_axi_``__name``_rresp;

// AXI-Lite slave flat signals (no ID, len, size, burst, user)
`define AXI_LITE_S(__name, __addr_t, __data_t, __strb_t) \
  logic                     s_``__name``_awvalid;   \
  __addr_t                  s_``__name``_awaddr;    \
  axi_pkg::prot_t           s_``__name``_awprot;    \
  logic                     s_``__name``_wvalid;    \
  __data_t                  s_``__name``_wdata;     \
  __strb_t                  s_``__name``_wstrb;     \
  logic                     s_``__name``_bready;    \
  logic                     s_``__name``_arvalid;   \
  __addr_t                  s_``__name``_araddr;    \
  axi_pkg::prot_t           s_``__name``_arprot;    \
  logic                     s_``__name``_rready;    \
  logic                     s_``__name``_awready;   \
  logic                     s_``__name``_wready;    \
  logic                     s_``__name``_bvalid;    \
  axi_pkg::resp_t           s_``__name``_bresp;     \
  logic                     s_``__name``_arready;   \
  logic                     s_``__name``_rvalid;    \
  __data_t                  s_``__name``_rdata;     \
  axi_pkg::resp_t           s_``__name``_rresp;

`endif // AXI_PORT_FLAT_SVH_