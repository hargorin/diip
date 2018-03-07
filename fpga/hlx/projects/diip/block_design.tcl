# ================================================================================
# block_design.tcl
# 
# Creates the block design
# 
# Can be copy-pasted from the output of vivados block design export to tcl
# 
# by Noah Huetter <noahhuetter@gmail.com>
# ================================================================================
# @Author: Noah Huetter
# @Date:   2017-11-24 15:21:33
# @Last Modified by:   Noah Huetter
# @Last Modified time: 2017-12-06 08:50:54

##
## Place Cells
##
# BRAM Controller
set vlnv xilinx.com:ip:axi_bram_ctrl:4.0
set name axi_bram_ctrl_0
cell $vlnv $name {} {}

# AXI GPIO to set transmission size
set vlnv xilinx.com:ip:axi_gpio:2.0
set name axi_gpio_0
cell $vlnv $name {
        C_ALL_OUTPUTS {1}
        C_DOUT_DEFAULT {0x00000400}
    } {}

# Two AXI Master Burst
set vlnv ime:diip:axi_master_burst:2.0 
set name axi_master_burst_0
cell $vlnv $name {} {}
set vlnv ime:diip:axi_master_burst:2.0 
set name axi_master_burst_1
cell $vlnv $name {} {}

# AXI Interconnect
set vlnv xilinx.com:ip:axi_interconnect:2.1 
set name axi_mem_intercon
cell $vlnv $name {
    NUM_MI {2}
    NUM_SI {3}
  } {}

# Block memory generator
set vlnv xilinx.com:ip:blk_mem_gen:8.3 
set name blk_mem_gen_0
cell $vlnv $name {
    Enable_B {Use_ENB_Pin}
    Memory_Type {True_Dual_Port_RAM}
    Port_B_Clock {100}
    Port_B_Enable_Rate {100}
    Port_B_Write_Rate {50}
    Use_RSTB_Pin {true}
  } {}

# Create debouncer
set vlnv ime:diip:debounce:1.0
set name debounce_0
cell $vlnv $name {} {}

# Create impulse generator
set vlnv ime:diip:impulse_generator:1.0
set name impulse_generator_0
cell $vlnv $name {
        C_IMPULSE_DURATION {1}
    } {}


# AXI JTAG
set vlnv xilinx.com:ip:jtag_axi:1.2 
set name jtag_axi_0
cell $vlnv $name {} {}

# System Reset
set vlnv xilinx.com:ip:proc_sys_reset:5.0 
set name rst_temac_support_0_125M
cell $vlnv $name {
    RESET_BOARD_INTERFACE {reset}
    USE_BOARD_FLOW {true}
  } {}

# TEMAC Support
set vlnv ime:diip:temac_support:1.0 
set name temac_support_0
cell $vlnv $name {} {}

# TEMAC
set vlnv xilinx.com:ip:tri_mode_ethernet_mac:9.0 
set name tri_mode_ethernet_mac_0
cell $vlnv $name {
    ETHERNET_BOARD_INTERFACE {rgmii}
    Frame_Filter {false}
    MDIO_BOARD_INTERFACE {mdio_io}
    Number_of_Table_Entries {0}
    Physical_Interface {RGMII}
    Statistics_Counters {false}
    USE_BOARD_FLOW {true}
  } {}

# UDP IP Stack
set vlnv ime:diip:udp_ip_stack:1.0 
set name udp_ip_stack_0
cell $vlnv $name {} {}

# UFT Stack
set vlnv ime:diip:uft_stack:1.0 
set name uft_stack_0
cell $vlnv $name {} {}

##
## Create Connections
##
# Create interface connections
# Create interface connections
connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]
connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTB]
connect_bd_intf_net -intf_net axi_master_burst_0_M_AXI [get_bd_intf_pins axi_master_burst_0/M_AXI] [get_bd_intf_pins axi_mem_intercon/S01_AXI]
connect_bd_intf_net -intf_net axi_master_burst_1_M_AXI [get_bd_intf_pins axi_master_burst_1/M_AXI] [get_bd_intf_pins axi_mem_intercon/S02_AXI]
connect_bd_intf_net -intf_net axi_mem_intercon_M00_AXI [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] [get_bd_intf_pins axi_mem_intercon/M00_AXI]
connect_bd_intf_net -intf_net axi_mem_intercon_M01_AXI [get_bd_intf_pins axi_gpio_0/S_AXI] [get_bd_intf_pins axi_mem_intercon/M01_AXI]
connect_bd_intf_net -intf_net jtag_axi_0_M_AXI [get_bd_intf_pins axi_mem_intercon/S00_AXI] [get_bd_intf_pins jtag_axi_0/M_AXI]
connect_bd_intf_net -intf_net temac_support_0_rx_axis [get_bd_intf_pins temac_support_0/rx_axis] [get_bd_intf_pins udp_ip_stack_0/mac_rx]
connect_bd_intf_net -intf_net temac_support_0_s_axi [get_bd_intf_pins temac_support_0/s_axi] [get_bd_intf_pins tri_mode_ethernet_mac_0/s_axi]
connect_bd_intf_net -intf_net temac_support_0_tx_axis_mac [get_bd_intf_pins temac_support_0/tx_axis_mac] [get_bd_intf_pins tri_mode_ethernet_mac_0/s_axis_tx]
connect_bd_intf_net -intf_net tri_mode_ethernet_mac_0_m_axis_rx [get_bd_intf_pins temac_support_0/rx_axis_mac] [get_bd_intf_pins tri_mode_ethernet_mac_0/m_axis_rx]
connect_bd_intf_net -intf_net tri_mode_ethernet_mac_0_mdio_external [get_bd_intf_ports mdio_io] [get_bd_intf_pins tri_mode_ethernet_mac_0/mdio_external]
connect_bd_intf_net -intf_net tri_mode_ethernet_mac_0_rgmii [get_bd_intf_ports rgmii] [get_bd_intf_pins tri_mode_ethernet_mac_0/rgmii]
connect_bd_intf_net -intf_net udp_ip_stack_0_mac_tx [get_bd_intf_pins temac_support_0/tx_axis] [get_bd_intf_pins udp_ip_stack_0/mac_tx]
connect_bd_intf_net -intf_net udp_ip_stack_0_udp_rx [get_bd_intf_pins udp_ip_stack_0/udp_rx] [get_bd_intf_pins uft_stack_0/udp_rx]
connect_bd_intf_net -intf_net uft_stack_0_udp_tx [get_bd_intf_pins udp_ip_stack_0/udp_tx] [get_bd_intf_pins uft_stack_0/udp_tx]

# Create port connections
connect_bd_net -net Net [get_bd_pins udp_ip_stack_0/our_ip_address] [get_bd_pins uft_stack_0/our_ip_address]
connect_bd_net -net Net1 [get_bd_pins udp_ip_stack_0/our_mac_address] [get_bd_pins uft_stack_0/our_mac_address]
connect_bd_net -net SW4_1 [get_bd_ports SW4] [get_bd_pins debounce_0/button]
connect_bd_net -net axi_gpio_0_gpio_io_o [get_bd_pins axi_gpio_0/gpio_io_o] [get_bd_pins uft_stack_0/tx_data_size]
connect_bd_net -net axi_master_burst_0_bus2ip_mst_cmd_timeout [get_bd_pins axi_master_burst_0/bus2ip_mst_cmd_timeout] [get_bd_pins uft_stack_0/bus2ip_mst_cmd_timeout]
connect_bd_net -net axi_master_burst_0_bus2ip_mst_cmdack [get_bd_pins axi_master_burst_0/bus2ip_mst_cmdack] [get_bd_pins uft_stack_0/bus2ip_mst_cmdack]
connect_bd_net -net axi_master_burst_0_bus2ip_mst_cmplt [get_bd_pins axi_master_burst_0/bus2ip_mst_cmplt] [get_bd_pins uft_stack_0/bus2ip_mst_cmplt]
connect_bd_net -net axi_master_burst_0_bus2ip_mst_error [get_bd_pins axi_master_burst_0/bus2ip_mst_error] [get_bd_pins uft_stack_0/bus2ip_mst_error]
connect_bd_net -net axi_master_burst_0_bus2ip_mst_rearbitrate [get_bd_pins axi_master_burst_0/bus2ip_mst_rearbitrate] [get_bd_pins uft_stack_0/bus2ip_mst_rearbitrate]
connect_bd_net -net axi_master_burst_0_bus2ip_mstrd_d [get_bd_pins axi_master_burst_0/bus2ip_mstrd_d] [get_bd_pins uft_stack_0/bus2ip_mstrd_d]
connect_bd_net -net axi_master_burst_0_bus2ip_mstrd_eof_n [get_bd_pins axi_master_burst_0/bus2ip_mstrd_eof_n] [get_bd_pins uft_stack_0/bus2ip_mstrd_eof_n]
connect_bd_net -net axi_master_burst_0_bus2ip_mstrd_rem [get_bd_pins axi_master_burst_0/bus2ip_mstrd_rem] [get_bd_pins uft_stack_0/bus2ip_mstrd_rem]
connect_bd_net -net axi_master_burst_0_bus2ip_mstrd_sof_n [get_bd_pins axi_master_burst_0/bus2ip_mstrd_sof_n] [get_bd_pins uft_stack_0/bus2ip_mstrd_sof_n]
connect_bd_net -net axi_master_burst_0_bus2ip_mstrd_src_dsc_n [get_bd_pins axi_master_burst_0/bus2ip_mstrd_src_dsc_n] [get_bd_pins uft_stack_0/bus2ip_mstrd_src_dsc_n]
connect_bd_net -net axi_master_burst_0_bus2ip_mstrd_src_rdy_n [get_bd_pins axi_master_burst_0/bus2ip_mstrd_src_rdy_n] [get_bd_pins uft_stack_0/bus2ip_mstrd_src_rdy_n]
connect_bd_net -net axi_master_burst_0_bus2ip_mstwr_dst_dsc_n [get_bd_pins axi_master_burst_0/bus2ip_mstwr_dst_dsc_n] [get_bd_pins uft_stack_0/bus2ip_mstwr_dst_dsc_n]
connect_bd_net -net axi_master_burst_0_bus2ip_mstwr_dst_rdy_n [get_bd_pins axi_master_burst_0/bus2ip_mstwr_dst_rdy_n] [get_bd_pins uft_stack_0/bus2ip_mstwr_dst_rdy_n]
connect_bd_net -net axi_master_burst_1_bus2ip_mst_cmd_timeout [get_bd_pins axi_master_burst_1/bus2ip_mst_cmd_timeout] [get_bd_pins uft_stack_0/tx_bus2ip_mst_cmd_timeout]
connect_bd_net -net axi_master_burst_1_bus2ip_mst_cmdack [get_bd_pins axi_master_burst_1/bus2ip_mst_cmdack] [get_bd_pins uft_stack_0/tx_bus2ip_mst_cmdack]
connect_bd_net -net axi_master_burst_1_bus2ip_mst_cmplt [get_bd_pins axi_master_burst_1/bus2ip_mst_cmplt] [get_bd_pins uft_stack_0/tx_bus2ip_mst_cmplt]
connect_bd_net -net axi_master_burst_1_bus2ip_mst_error [get_bd_pins axi_master_burst_1/bus2ip_mst_error] [get_bd_pins uft_stack_0/tx_bus2ip_mst_error]
connect_bd_net -net axi_master_burst_1_bus2ip_mst_rearbitrate [get_bd_pins axi_master_burst_1/bus2ip_mst_rearbitrate] [get_bd_pins uft_stack_0/tx_bus2ip_mst_rearbitrate]
connect_bd_net -net axi_master_burst_1_bus2ip_mstrd_d [get_bd_pins axi_master_burst_1/bus2ip_mstrd_d] [get_bd_pins uft_stack_0/tx_bus2ip_mstrd_d]
connect_bd_net -net axi_master_burst_1_bus2ip_mstrd_eof_n [get_bd_pins axi_master_burst_1/bus2ip_mstrd_eof_n] [get_bd_pins uft_stack_0/tx_bus2ip_mstrd_eof_n]
connect_bd_net -net axi_master_burst_1_bus2ip_mstrd_rem [get_bd_pins axi_master_burst_1/bus2ip_mstrd_rem] [get_bd_pins uft_stack_0/tx_bus2ip_mstrd_rem]
connect_bd_net -net axi_master_burst_1_bus2ip_mstrd_sof_n [get_bd_pins axi_master_burst_1/bus2ip_mstrd_sof_n] [get_bd_pins uft_stack_0/tx_bus2ip_mstrd_sof_n]
connect_bd_net -net axi_master_burst_1_bus2ip_mstrd_src_dsc_n [get_bd_pins axi_master_burst_1/bus2ip_mstrd_src_dsc_n] [get_bd_pins uft_stack_0/tx_bus2ip_mstrd_src_dsc_n]
connect_bd_net -net axi_master_burst_1_bus2ip_mstrd_src_rdy_n [get_bd_pins axi_master_burst_1/bus2ip_mstrd_src_rdy_n] [get_bd_pins uft_stack_0/tx_bus2ip_mstrd_src_rdy_n]
connect_bd_net -net axi_master_burst_1_bus2ip_mstwr_dst_dsc_n [get_bd_pins axi_master_burst_1/bus2ip_mstwr_dst_dsc_n] [get_bd_pins uft_stack_0/tx_bus2ip_mstwr_dst_dsc_n]
connect_bd_net -net axi_master_burst_1_bus2ip_mstwr_dst_rdy_n [get_bd_pins axi_master_burst_1/bus2ip_mstwr_dst_rdy_n] [get_bd_pins uft_stack_0/tx_bus2ip_mstwr_dst_rdy_n]
connect_bd_net -net clk_in_n_1 [get_bd_ports clk_in_n] [get_bd_pins temac_support_0/clk_in_n]
connect_bd_net -net clk_in_p_1 [get_bd_ports clk_in_p] [get_bd_pins temac_support_0/clk_in_p]
connect_bd_net -net debounce_0_result [get_bd_pins debounce_0/result] [get_bd_pins impulse_generator_0/enable]
connect_bd_net -net impulse_generator_0_impulse [get_bd_pins impulse_generator_0/impulse] [get_bd_pins uft_stack_0/tx_start]
connect_bd_net -net reset_1 [get_bd_ports reset] [get_bd_pins rst_temac_support_0_125M/ext_reset_in] [get_bd_pins temac_support_0/glbl_rst] [get_bd_pins udp_ip_stack_0/reset]
connect_bd_net -net rst_temac_support_0_125M_interconnect_aresetn [get_bd_pins axi_mem_intercon/ARESETN] [get_bd_pins rst_temac_support_0_125M/interconnect_aresetn]
connect_bd_net -net rst_temac_support_0_125M_peripheral_aresetn [get_bd_pins axi_gpio_0/s_axi_aresetn] [get_bd_pins axi_mem_intercon/M01_ARESETN] [get_bd_pins axi_mem_intercon/S00_ARESETN] [get_bd_pins axi_mem_intercon/S01_ARESETN] [get_bd_pins axi_mem_intercon/S02_ARESETN] [get_bd_pins jtag_axi_0/aresetn] [get_bd_pins rst_temac_support_0_125M/peripheral_aresetn]
connect_bd_net -net speed_1 [get_bd_ports speed] [get_bd_pins temac_support_0/speed]
connect_bd_net -net temac_support_0_glbl_rstn [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins axi_master_burst_0/m_axi_aresetn] [get_bd_pins axi_master_burst_1/m_axi_aresetn] [get_bd_pins axi_mem_intercon/M00_ARESETN] [get_bd_pins temac_support_0/glbl_rstn] [get_bd_pins tri_mode_ethernet_mac_0/glbl_rstn] [get_bd_pins uft_stack_0/rst_n]
connect_bd_net -net temac_support_0_gtx_clk [get_bd_pins temac_support_0/gtx_clk] [get_bd_pins tri_mode_ethernet_mac_0/gtx_clk]
connect_bd_net -net temac_support_0_gtx_clk90 [get_bd_pins temac_support_0/gtx_clk90] [get_bd_pins tri_mode_ethernet_mac_0/gtx_clk90]
connect_bd_net -net temac_support_0_gtx_clk_bufg_out [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_gpio_0/s_axi_aclk] [get_bd_pins axi_master_burst_0/m_axi_aclk] [get_bd_pins axi_master_burst_1/m_axi_aclk] [get_bd_pins axi_mem_intercon/ACLK] [get_bd_pins axi_mem_intercon/M00_ACLK] [get_bd_pins axi_mem_intercon/M01_ACLK] [get_bd_pins axi_mem_intercon/S00_ACLK] [get_bd_pins axi_mem_intercon/S01_ACLK] [get_bd_pins axi_mem_intercon/S02_ACLK] [get_bd_pins debounce_0/clk] [get_bd_pins impulse_generator_0/clk] [get_bd_pins jtag_axi_0/aclk] [get_bd_pins rst_temac_support_0_125M/slowest_sync_clk] [get_bd_pins temac_support_0/gtx_clk_bufg_out] [get_bd_pins udp_ip_stack_0/rx_clk] [get_bd_pins udp_ip_stack_0/tx_clk] [get_bd_pins uft_stack_0/clk]
connect_bd_net -net temac_support_0_phy_resetn [get_bd_ports phy_resetn] [get_bd_pins temac_support_0/phy_resetn]
connect_bd_net -net temac_support_0_rx_axi_rstn [get_bd_pins temac_support_0/rx_axi_rstn] [get_bd_pins tri_mode_ethernet_mac_0/rx_axi_rstn]
connect_bd_net -net temac_support_0_s_axi_aclk [get_bd_pins temac_support_0/s_axi_aclk] [get_bd_pins tri_mode_ethernet_mac_0/s_axi_aclk]
connect_bd_net -net temac_support_0_s_axi_resetn [get_bd_pins temac_support_0/s_axi_resetn] [get_bd_pins tri_mode_ethernet_mac_0/s_axi_resetn]
connect_bd_net -net temac_support_0_tx_axi_rstn [get_bd_pins temac_support_0/tx_axi_rstn] [get_bd_pins tri_mode_ethernet_mac_0/tx_axi_rstn]
connect_bd_net -net temac_support_0_tx_ifg_delay [get_bd_pins temac_support_0/tx_ifg_delay] [get_bd_pins tri_mode_ethernet_mac_0/tx_ifg_delay]
connect_bd_net -net tri_mode_ethernet_mac_0_rx_enable [get_bd_pins temac_support_0/rx_enable] [get_bd_pins tri_mode_ethernet_mac_0/rx_enable]
connect_bd_net -net tri_mode_ethernet_mac_0_rx_mac_aclk [get_bd_pins temac_support_0/rx_mac_aclk] [get_bd_pins tri_mode_ethernet_mac_0/rx_mac_aclk]
connect_bd_net -net tri_mode_ethernet_mac_0_rx_reset [get_bd_pins temac_support_0/rx_reset] [get_bd_pins tri_mode_ethernet_mac_0/rx_reset]
connect_bd_net -net tri_mode_ethernet_mac_0_speedis100 [get_bd_pins temac_support_0/speedis100] [get_bd_pins tri_mode_ethernet_mac_0/speedis100]
connect_bd_net -net tri_mode_ethernet_mac_0_speedis10100 [get_bd_pins temac_support_0/speedis10100] [get_bd_pins tri_mode_ethernet_mac_0/speedis10100]
connect_bd_net -net tri_mode_ethernet_mac_0_tx_enable [get_bd_pins temac_support_0/tx_enable] [get_bd_pins tri_mode_ethernet_mac_0/tx_enable]
connect_bd_net -net tri_mode_ethernet_mac_0_tx_mac_aclk [get_bd_pins temac_support_0/tx_mac_aclk] [get_bd_pins tri_mode_ethernet_mac_0/tx_mac_aclk]
connect_bd_net -net tri_mode_ethernet_mac_0_tx_reset [get_bd_pins temac_support_0/tx_reset] [get_bd_pins tri_mode_ethernet_mac_0/tx_reset]
connect_bd_net -net udp_ip_stack_0_udp_rx_start [get_bd_pins udp_ip_stack_0/udp_rx_start] [get_bd_pins uft_stack_0/udp_rx_start]
connect_bd_net -net udp_ip_stack_0_udp_rxo_hdr_data_length [get_bd_pins udp_ip_stack_0/udp_rxo_hdr_data_length] [get_bd_pins uft_stack_0/udp_rx_hdr_data_length]
connect_bd_net -net udp_ip_stack_0_udp_rxo_hdr_dst_port [get_bd_pins udp_ip_stack_0/udp_rxo_hdr_dst_port] [get_bd_pins uft_stack_0/udp_rx_hdr_dst_port]
connect_bd_net -net udp_ip_stack_0_udp_rxo_hdr_is_valid [get_bd_pins udp_ip_stack_0/udp_rxo_hdr_is_valid] [get_bd_pins uft_stack_0/udp_rx_hdr_is_valid]
connect_bd_net -net udp_ip_stack_0_udp_rxo_hdr_src_ip_addr [get_bd_pins udp_ip_stack_0/udp_rxo_hdr_src_ip_addr] [get_bd_pins uft_stack_0/udp_rx_hdr_src_ip_addr]
connect_bd_net -net udp_ip_stack_0_udp_rxo_hdr_src_port [get_bd_pins udp_ip_stack_0/udp_rxo_hdr_src_port] [get_bd_pins uft_stack_0/udp_rx_hdr_src_port]
connect_bd_net -net udp_ip_stack_0_udp_tx_result [get_bd_pins udp_ip_stack_0/udp_tx_result] [get_bd_pins uft_stack_0/udp_tx_result]
connect_bd_net -net uft_stack_0_ip2bus_mst_addr [get_bd_pins axi_master_burst_0/ip2bus_mst_addr] [get_bd_pins uft_stack_0/ip2bus_mst_addr]
connect_bd_net -net uft_stack_0_ip2bus_mst_be [get_bd_pins axi_master_burst_0/ip2bus_mst_be] [get_bd_pins uft_stack_0/ip2bus_mst_be]
connect_bd_net -net uft_stack_0_ip2bus_mst_length [get_bd_pins axi_master_burst_0/ip2bus_mst_length] [get_bd_pins uft_stack_0/ip2bus_mst_length]
connect_bd_net -net uft_stack_0_ip2bus_mst_lock [get_bd_pins axi_master_burst_0/ip2bus_mst_lock] [get_bd_pins uft_stack_0/ip2bus_mst_lock]
connect_bd_net -net uft_stack_0_ip2bus_mst_reset [get_bd_pins axi_master_burst_0/ip2bus_mst_reset] [get_bd_pins uft_stack_0/ip2bus_mst_reset]
connect_bd_net -net uft_stack_0_ip2bus_mst_type [get_bd_pins axi_master_burst_0/ip2bus_mst_type] [get_bd_pins uft_stack_0/ip2bus_mst_type]
connect_bd_net -net uft_stack_0_ip2bus_mstrd_dst_dsc_n [get_bd_pins axi_master_burst_0/ip2bus_mstrd_dst_dsc_n] [get_bd_pins uft_stack_0/ip2bus_mstrd_dst_dsc_n]
connect_bd_net -net uft_stack_0_ip2bus_mstrd_dst_rdy_n [get_bd_pins axi_master_burst_0/ip2bus_mstrd_dst_rdy_n] [get_bd_pins uft_stack_0/ip2bus_mstrd_dst_rdy_n]
connect_bd_net -net uft_stack_0_ip2bus_mstrd_req [get_bd_pins axi_master_burst_0/ip2bus_mstrd_req] [get_bd_pins uft_stack_0/ip2bus_mstrd_req]
connect_bd_net -net uft_stack_0_ip2bus_mstwr_d [get_bd_pins axi_master_burst_0/ip2bus_mstwr_d] [get_bd_pins uft_stack_0/ip2bus_mstwr_d]
connect_bd_net -net uft_stack_0_ip2bus_mstwr_eof_n [get_bd_pins axi_master_burst_0/ip2bus_mstwr_eof_n] [get_bd_pins uft_stack_0/ip2bus_mstwr_eof_n]
connect_bd_net -net uft_stack_0_ip2bus_mstwr_rem [get_bd_pins axi_master_burst_0/ip2bus_mstwr_rem] [get_bd_pins uft_stack_0/ip2bus_mstwr_rem]
connect_bd_net -net uft_stack_0_ip2bus_mstwr_req [get_bd_pins axi_master_burst_0/ip2bus_mstwr_req] [get_bd_pins uft_stack_0/ip2bus_mstwr_req]
connect_bd_net -net uft_stack_0_ip2bus_mstwr_sof_n [get_bd_pins axi_master_burst_0/ip2bus_mstwr_sof_n] [get_bd_pins uft_stack_0/ip2bus_mstwr_sof_n]
connect_bd_net -net uft_stack_0_ip2bus_mstwr_src_dsc_n [get_bd_pins axi_master_burst_0/ip2bus_mstwr_src_dsc_n] [get_bd_pins uft_stack_0/ip2bus_mstwr_src_dsc_n]
connect_bd_net -net uft_stack_0_ip2bus_mstwr_src_rdy_n [get_bd_pins axi_master_burst_0/ip2bus_mstwr_src_rdy_n] [get_bd_pins uft_stack_0/ip2bus_mstwr_src_rdy_n]
connect_bd_net -net uft_stack_0_tx_ip2bus_mst_addr [get_bd_pins axi_master_burst_1/ip2bus_mst_addr] [get_bd_pins uft_stack_0/tx_ip2bus_mst_addr]
connect_bd_net -net uft_stack_0_tx_ip2bus_mst_be [get_bd_pins axi_master_burst_1/ip2bus_mst_be] [get_bd_pins uft_stack_0/tx_ip2bus_mst_be]
connect_bd_net -net uft_stack_0_tx_ip2bus_mst_length [get_bd_pins axi_master_burst_1/ip2bus_mst_length] [get_bd_pins uft_stack_0/tx_ip2bus_mst_length]
connect_bd_net -net uft_stack_0_tx_ip2bus_mst_lock [get_bd_pins axi_master_burst_1/ip2bus_mst_lock] [get_bd_pins uft_stack_0/tx_ip2bus_mst_lock]
connect_bd_net -net uft_stack_0_tx_ip2bus_mst_reset [get_bd_pins axi_master_burst_1/ip2bus_mst_reset] [get_bd_pins uft_stack_0/tx_ip2bus_mst_reset]
connect_bd_net -net uft_stack_0_tx_ip2bus_mst_type [get_bd_pins axi_master_burst_1/ip2bus_mst_type] [get_bd_pins uft_stack_0/tx_ip2bus_mst_type]
connect_bd_net -net uft_stack_0_tx_ip2bus_mstrd_dst_dsc_n [get_bd_pins axi_master_burst_1/ip2bus_mstrd_dst_dsc_n] [get_bd_pins uft_stack_0/tx_ip2bus_mstrd_dst_dsc_n]
connect_bd_net -net uft_stack_0_tx_ip2bus_mstrd_dst_rdy_n [get_bd_pins axi_master_burst_1/ip2bus_mstrd_dst_rdy_n] [get_bd_pins uft_stack_0/tx_ip2bus_mstrd_dst_rdy_n]
connect_bd_net -net uft_stack_0_tx_ip2bus_mstrd_req [get_bd_pins axi_master_burst_1/ip2bus_mstrd_req] [get_bd_pins uft_stack_0/tx_ip2bus_mstrd_req]
connect_bd_net -net uft_stack_0_tx_ip2bus_mstwr_d [get_bd_pins axi_master_burst_1/ip2bus_mstwr_d] [get_bd_pins uft_stack_0/tx_ip2bus_mstwr_d]
connect_bd_net -net uft_stack_0_tx_ip2bus_mstwr_eof_n [get_bd_pins axi_master_burst_1/ip2bus_mstwr_eof_n] [get_bd_pins uft_stack_0/tx_ip2bus_mstwr_eof_n]
connect_bd_net -net uft_stack_0_tx_ip2bus_mstwr_rem [get_bd_pins axi_master_burst_1/ip2bus_mstwr_rem] [get_bd_pins uft_stack_0/tx_ip2bus_mstwr_rem]
connect_bd_net -net uft_stack_0_tx_ip2bus_mstwr_req [get_bd_pins axi_master_burst_1/ip2bus_mstwr_req] [get_bd_pins uft_stack_0/tx_ip2bus_mstwr_req]
connect_bd_net -net uft_stack_0_tx_ip2bus_mstwr_sof_n [get_bd_pins axi_master_burst_1/ip2bus_mstwr_sof_n] [get_bd_pins uft_stack_0/tx_ip2bus_mstwr_sof_n]
connect_bd_net -net uft_stack_0_tx_ip2bus_mstwr_src_dsc_n [get_bd_pins axi_master_burst_1/ip2bus_mstwr_src_dsc_n] [get_bd_pins uft_stack_0/tx_ip2bus_mstwr_src_dsc_n]
connect_bd_net -net uft_stack_0_tx_ip2bus_mstwr_src_rdy_n [get_bd_pins axi_master_burst_1/ip2bus_mstwr_src_rdy_n] [get_bd_pins uft_stack_0/tx_ip2bus_mstwr_src_rdy_n]
connect_bd_net -net uft_stack_0_tx_ready [get_bd_ports led0] [get_bd_pins uft_stack_0/tx_ready]
connect_bd_net -net uft_stack_0_udp_tx_hdr_checksum [get_bd_pins udp_ip_stack_0/udp_txi_hdr_checksum] [get_bd_pins uft_stack_0/udp_tx_hdr_checksum]
connect_bd_net -net uft_stack_0_udp_tx_hdr_data_length [get_bd_pins udp_ip_stack_0/udp_txi_hdr_data_length] [get_bd_pins uft_stack_0/udp_tx_hdr_data_length]
connect_bd_net -net uft_stack_0_udp_tx_hdr_dst_ip_addr [get_bd_pins udp_ip_stack_0/udp_txi_hdr_dst_ip_addr] [get_bd_pins uft_stack_0/udp_tx_hdr_dst_ip_addr]
connect_bd_net -net uft_stack_0_udp_tx_hdr_dst_port [get_bd_pins udp_ip_stack_0/udp_txi_hdr_dst_port] [get_bd_pins uft_stack_0/udp_tx_hdr_dst_port]
connect_bd_net -net uft_stack_0_udp_tx_hdr_src_port [get_bd_pins udp_ip_stack_0/udp_txi_hdr_src_port] [get_bd_pins uft_stack_0/udp_tx_hdr_src_port]
connect_bd_net -net uft_stack_0_udp_tx_start [get_bd_pins udp_ip_stack_0/udp_tx_start] [get_bd_pins uft_stack_0/udp_tx_start]
connect_bd_net -net update_speed_1 [get_bd_ports update_speed] [get_bd_pins temac_support_0/update_speed]

# Create address segments
create_bd_addr_seg -range 0x00080000 -offset 0x08000000 [get_bd_addr_spaces axi_master_burst_0/m_axi] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] SEG_axi_bram_ctrl_0_Mem0
create_bd_addr_seg -range 0x00001000 -offset 0x40000000 [get_bd_addr_spaces axi_master_burst_0/m_axi] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] SEG_axi_gpio_0_Reg
create_bd_addr_seg -range 0x00080000 -offset 0x08000000 [get_bd_addr_spaces axi_master_burst_1/m_axi] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] SEG_axi_bram_ctrl_0_Mem0
create_bd_addr_seg -range 0x00001000 -offset 0x40000000 [get_bd_addr_spaces axi_master_burst_1/m_axi] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] SEG_axi_gpio_0_Reg
create_bd_addr_seg -range 0x00080000 -offset 0x08000000 [get_bd_addr_spaces jtag_axi_0/Data] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] SEG_axi_bram_ctrl_0_Mem0
create_bd_addr_seg -range 0x00001000 -offset 0x40000000 [get_bd_addr_spaces jtag_axi_0/Data] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] SEG_axi_gpio_0_Reg
create_bd_addr_seg -range 0x00001000 -offset 0x00000000 [get_bd_addr_spaces temac_support_0/s_axi] [get_bd_addr_segs tri_mode_ethernet_mac_0/s_axi/Reg] SEG_tri_mode_ethernet_mac_0_Reg





