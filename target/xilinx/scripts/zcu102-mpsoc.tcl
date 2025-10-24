  GNU nano 6.2                                                                                          OLDreckon_zynq_AXI/vivado_commands                                                                                                   
open_project ${project_root}/${proj}.xpr

create_bd_design "ps"

create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.4 zynq_ultra_ps_e_0

set_property CONFIG.PSU__USE__M_AXI_GP2 {0} [get_bd_cells zynq_ultra_ps_e_0]

close_bd_design [get_bd_designs "ps"]