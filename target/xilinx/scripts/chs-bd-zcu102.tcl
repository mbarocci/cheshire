set design_name ${board}_mpsoc

set_property -name "board_part" -value "xilinx.com:zcu102:part0:3.4" -objects [current_project]

create_bd_design $design_name

## MPSoC
#Vivado 2024.2
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.5 zynq_ultra_ps_e_0 

#create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.4 zynq_ultra_ps_e_0

set_property -dict [list \
  CONFIG.PSU__DDRC__ENABLE {0} \
  CONFIG.PSU__MAXIGP0__DATA_WIDTH {32} \
  CONFIG.PSU__UART0__PERIPHERAL__ENABLE {1} \
  CONFIG.PSU__USE__M_AXI_GP0 {1} \
  CONFIG.PSU__USE__M_AXI_GP2 {0} \
  CONFIG.PSU__FPGA_PL0_ENABLE {0} \
] [get_bd_cells zynq_ultra_ps_e_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0

# set_property -dict  [list \
#   CONFIG.CLK_IN1_BOARD_INTERFACE {user_si570_sysclk} \
#   CONFIG.RESET_BOARD_INTERFACE {Custom} \
#   CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} \
#   CONFIG.CLKOUT2_USED {true} \
#   CONFIG.USE_LOCKED {false} \
#   CONFIG.USE_RESET {false} \
#   CONFIG.CLKOUT3_USED {true} \
#   CONFIG.CLKOUT4_USED {true} \
#   CONFIG.CLK_OUT1_PORT {clk_100} \
#   CONFIG.CLK_OUT2_PORT {clk_50} \
#   CONFIG.CLK_OUT3_PORT {clk_20} \
#   CONFIG.CLK_OUT4_PORT {clk_10} \
#   CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {50.000} \
#   CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {20.000} \
#   CONFIG.CLKOUT4_REQUESTED_OUT_FREQ {10.000} \
#   CONFIG.PRIM_SOURCE {No_buffer} \
#   CONFIG.MMCM_CLKOUT1_DIVIDE {24} \
#   CONFIG.MMCM_CLKOUT2_DIVIDE {60} \
#   CONFIG.MMCM_CLKOUT3_DIVIDE {120} \ f
#   CONFIG.NUM_OUT_CLKS {4} \
#   CONFIG.CLKOUT2_JITTER {132.683} \
#   CONFIG.CLKOUT2_PHASE_ERROR {87.180} \
#   CONFIG.CLKOUT3_JITTER {162.167} \
#   CONFIG.CLKOUT3_PHASE_ERROR {87.180} \
#   CONFIG.CLKOUT4_JITTER {188.586} \
#   CONFIG.CLKOUT4_PHASE_ERROR {87.180} \
# ] [get_bd_cells clk_wiz_0]

set_property -dict [list \
  CONFIG.CLK_IN1_BOARD_INTERFACE {Custom} \
  CONFIG.RESET_BOARD_INTERFACE {Custom} \
  CONFIG.USE_RESET {true} \
  CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} \
  CONFIG.PRIM_IN_FREQ {125.000} \
  CONFIG.CLKOUT1_USED {true} \
  CONFIG.CLKOUT2_USED {true} \
  CONFIG.CLKOUT3_USED {true} \
  CONFIG.CLKOUT4_USED {true} \
  CONFIG.CLK_OUT1_PORT {clk_50} \
  CONFIG.CLK_OUT2_PORT {clk_48} \
  CONFIG.CLK_OUT3_PORT {clk_20} \
  CONFIG.CLK_OUT4_PORT {clk_15} \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50.000} \
  CONFIG.CLKOUT1_JITTER {116.415} \
  CONFIG.CLKOUT1_PHASE_ERROR {77.836} \
  CONFIG.CLKOUT2_JITTER {117.369} \
  CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {48.000} \
  CONFIG.CLKOUT3_JITTER {140.023} \
  CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {20.000} \
  CONFIG.CLKOUT4_JITTER {160.570} \
  CONFIG.CLKOUT4_PHASE_ERROR {77.836} \
  CONFIG.CLKOUT4_REQUESTED_OUT_FREQ {15.000} \
  ] [get_bd_cells clk_wiz_0]

create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 CLK_IN1_D
set_property CONFIG.FREQ_HZ 125000000 [get_bd_intf_ports /CLK_IN1_D]
connect_bd_intf_net [get_bd_intf_pins clk_wiz_0/CLK_IN1_D] [get_bd_intf_ports CLK_IN1_D]

create_bd_port -dir O -type clk clk_48
connect_bd_net [get_bd_pins /clk_wiz_0/clk_48] [get_bd_ports clk_48]

create_bd_port -dir O -type clk clk_50
connect_bd_net [get_bd_pins /clk_wiz_0/clk_50] [get_bd_ports clk_50]

create_bd_port -dir O -type clk clk_20
connect_bd_net [get_bd_pins /clk_wiz_0/clk_20] [get_bd_ports clk_20]

create_bd_port -dir O -type clk clk_15
connect_bd_net [get_bd_pins /clk_wiz_0/clk_15] [get_bd_ports clk_15]

# VIO

create_bd_cell -type ip -vlnv xilinx.com:ip:vio:3.0 vio_0

set_property -dict [list \
  CONFIG.C_NUM_PROBE_OUT {4} \
  CONFIG.C_PROBE_OUT0_INIT_VAL {0x0} \
  CONFIG.C_PROBE_OUT1_INIT_VAL {0x2} \
  CONFIG.C_PROBE_OUT2_INIT_VAL {0x1} \
  CONFIG.C_PROBE_OUT3_INIT_VAL {0x0} \
  CONFIG.C_PROBE_OUT1_WIDTH {2} \
  CONFIG.C_EN_PROBE_IN_ACTIVITY {0} \
  CONFIG.C_NUM_PROBE_IN {2} \
] [get_bd_cells vio_0]

connect_bd_net [get_bd_pins clk_wiz_0/clk_50] [get_bd_pins vio_0/clk]

create_bd_port -dir I -from 0 -to 0 probe_in0
connect_bd_net [get_bd_pins /vio_0/probe_in0] [get_bd_ports probe_in0]

create_bd_port -dir I -from 0 -to 0 probe_in1
connect_bd_net [get_bd_pins /vio_0/probe_in1] [get_bd_ports probe_in1]

create_bd_port -dir O -from 0 -to 0 probe_out0
connect_bd_net [get_bd_pins /vio_0/probe_out0] [get_bd_ports probe_out0]

create_bd_port -dir O -from 0 -to 0 probe_out1
connect_bd_net [get_bd_pins /vio_0/probe_out1] [get_bd_ports probe_out1]

create_bd_port -dir O -from 0 -to 0 probe_out2
connect_bd_net [get_bd_pins /vio_0/probe_out2] [get_bd_ports probe_out2]

create_bd_port -dir O -from 0 -to 0 probe_out3
connect_bd_net [get_bd_pins /vio_0/probe_out3] [get_bd_ports probe_out3]

# BRAM
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0
set_property -dict [list CONFIG.SINGLE_PORT_BRAM {1}] [get_bd_cells axi_bram_ctrl_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0

set_property -dict [list \
  CONFIG.NUM_MI {1} \
  CONFIG.NUM_SI {1} \
] [get_bd_cells smartconnect_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0

connect_bd_net [get_bd_pins /clk_wiz_0/clk_50] [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_fpd_aclk]
connect_bd_net [get_bd_pins /clk_wiz_0/clk_50] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]
connect_bd_net [get_bd_pins /clk_wiz_0/clk_50] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
connect_bd_net [get_bd_pins /clk_wiz_0/clk_50] [get_bd_pins smartconnect_0/aclk]

connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] [get_bd_pins proc_sys_reset_0/ext_reset_in]
connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins smartconnect_0/aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]

connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_FPD] [get_bd_intf_pins smartconnect_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]

update_compile_order -fileset sources_1

delete_bd_objs [get_bd_addr_segs] [get_bd_addr_segs -excluded]

assign_bd_address -target_address_space /zynq_ultra_ps_e_0/Data [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
set_property offset 0x00A0000000 [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_axi_bram_ctrl_0_Mem0}]
set_property range 256K [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_axi_bram_ctrl_0_Mem0}]

create_bd_intf_port -mode Master -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORTA
set_property CONFIG.MASTER_TYPE [get_property CONFIG.MASTER_TYPE [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]] [get_bd_intf_ports BRAM_PORTA]
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_ports BRAM_PORTA]
set_property CONFIG.READ_WRITE_MODE READ_WRITE [get_bd_intf_ports /BRAM_PORTA]

regenerate_bd_layout
validate_bd_design

save_bd_design

close_bd_design [get_bd_designs $design_name]

set bd_path [ make_wrapper -fileset sources_1 -files [get_files -norecurse ${board}_mpsoc.bd] -top ]
add_files -norecurse -fileset sources_1 $bd_path

set_property source_mgmt_mode DisplayOnly [current_project]
