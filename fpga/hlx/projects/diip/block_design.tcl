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
# @Last Modified by:   Noah
# @Last Modified time: 2018-04-25 18:13:38

  ##
  ## Add specific IP repo path
  ##
  set curr_path [get_property  ip_repo_paths [current_project]]
  set_property ip_repo_paths "$curr_path/ ../hls/stream_dummy/project/stream_dummy/stream_dummy/impl/ip ../hls/controller/project/controller/controller/impl/ip" [current_project]
  update_ip_catalog

  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_0 ]

  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0 ]
  set_property -dict [ list \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.C_DOUT_DEFAULT {0x00000400} \
 ] $axi_gpio_0

  # Create instance: axi_master_burst_0, and set properties
  set axi_master_burst_0 [ create_bd_cell -type ip -vlnv ime:diip:axi_master_burst:2.1 axi_master_burst_0 ]

  # Create instance: axi_master_burst_1, and set properties
  set axi_master_burst_1 [ create_bd_cell -type ip -vlnv ime:diip:axi_master_burst:2.1 axi_master_burst_1 ]

  # Create instance: axi_mem_intercon, and set properties
  set axi_mem_intercon [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_mem_intercon ]
  set_property -dict [ list \
   CONFIG.NUM_MI {2} \
   CONFIG.NUM_SI {4} \
 ] $axi_mem_intercon

  # Create instance: blk_mem_gen_0, and set properties
  set blk_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0 ]
  set_property -dict [ list \
   CONFIG.Enable_B {Use_ENB_Pin} \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.Port_B_Clock {100} \
   CONFIG.Port_B_Enable_Rate {100} \
   CONFIG.Port_B_Write_Rate {50} \
   CONFIG.Use_RSTB_Pin {true} \
 ] $blk_mem_gen_0

  # Create instance: controller_top_0, and set properties
  set controller_top_0 [ create_bd_cell -type ip -vlnv ime:diip:controller_top:0.1 controller_top_0 ]

  # Create instance: debounce_0, and set properties
  set debounce_0 [ create_bd_cell -type ip -vlnv ime:diip:debounce:1.0 debounce_0 ]

  # Create instance: impulse_generator_0, and set properties
  set impulse_generator_0 [ create_bd_cell -type ip -vlnv ime:diip:impulse_generator:1.0 impulse_generator_0 ]
  set_property -dict [ list \
   CONFIG.C_IMPULSE_DURATION {1} \
 ] $impulse_generator_0

  # Create instance: jtag_axi_0, and set properties
  set jtag_axi_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:jtag_axi:1.2 jtag_axi_0 ]

  # Create instance: rst_temac_support_0_125M, and set properties
  set rst_temac_support_0_125M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_temac_support_0_125M ]
  set_property -dict [ list \
   CONFIG.RESET_BOARD_INTERFACE {reset} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $rst_temac_support_0_125M

  # Create instance: stream_dummy_top_0, and set properties
  set stream_dummy_top_0 [ create_bd_cell -type ip -vlnv xilinx.com:hls:stream_dummy_top:1.0 stream_dummy_top_0 ]

  # Create instance: temac_support_0, and set properties
  set temac_support_0 [ create_bd_cell -type ip -vlnv ime:diip:temac_support:1.0 temac_support_0 ]

  # Create instance: tri_mode_ethernet_mac_0, and set properties
  set tri_mode_ethernet_mac_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tri_mode_ethernet_mac:9.0 tri_mode_ethernet_mac_0 ]
  set_property -dict [ list \
   CONFIG.ETHERNET_BOARD_INTERFACE {rgmii} \
   CONFIG.Frame_Filter {false} \
   CONFIG.MDIO_BOARD_INTERFACE {mdio_io} \
   CONFIG.Number_of_Table_Entries {0} \
   CONFIG.Physical_Interface {RGMII} \
   CONFIG.Statistics_Counters {false} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $tri_mode_ethernet_mac_0

  # Create instance: udp_ip_stack_0, and set properties
  set udp_ip_stack_0 [ create_bd_cell -type ip -vlnv ime:diip:udp_ip_stack:1.0 udp_ip_stack_0 ]

  # Create instance: uft_stack_0, and set properties
  set uft_stack_0 [ create_bd_cell -type ip -vlnv ime:diip:uft_stack:1.1 uft_stack_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_master_burst_0_M_AXI [get_bd_intf_pins axi_master_burst_0/M_AXI] [get_bd_intf_pins axi_mem_intercon/S01_AXI]
  connect_bd_intf_net -intf_net axi_master_burst_1_M_AXI [get_bd_intf_pins axi_master_burst_1/M_AXI] [get_bd_intf_pins axi_mem_intercon/S02_AXI]
  connect_bd_intf_net -intf_net axi_mem_intercon_M00_AXI [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] [get_bd_intf_pins axi_mem_intercon/M00_AXI]
  connect_bd_intf_net -intf_net axi_mem_intercon_M01_AXI [get_bd_intf_pins axi_gpio_0/S_AXI] [get_bd_intf_pins axi_mem_intercon/M01_AXI]
  connect_bd_intf_net -intf_net controller_top_0_m_axi_memp [get_bd_intf_pins axi_mem_intercon/S03_AXI] [get_bd_intf_pins controller_top_0/m_axi_memp]
  connect_bd_intf_net -intf_net controller_top_0_outData [get_bd_intf_pins controller_top_0/outData] [get_bd_intf_pins stream_dummy_top_0/inData]
  connect_bd_intf_net -intf_net jtag_axi_0_M_AXI [get_bd_intf_pins axi_mem_intercon/S00_AXI] [get_bd_intf_pins jtag_axi_0/M_AXI]
  connect_bd_intf_net -intf_net stream_dummy_top_0_outData [get_bd_intf_pins controller_top_0/inData] [get_bd_intf_pins stream_dummy_top_0/outData]
  connect_bd_intf_net -intf_net temac_support_0_rx_axis [get_bd_intf_pins temac_support_0/rx_axis] [get_bd_intf_pins udp_ip_stack_0/mac_rx]
  connect_bd_intf_net -intf_net temac_support_0_s_axi [get_bd_intf_pins temac_support_0/s_axi] [get_bd_intf_pins tri_mode_ethernet_mac_0/s_axi]
  connect_bd_intf_net -intf_net temac_support_0_tx_axis_mac [get_bd_intf_pins temac_support_0/tx_axis_mac] [get_bd_intf_pins tri_mode_ethernet_mac_0/s_axis_tx]
  connect_bd_intf_net -intf_net tri_mode_ethernet_mac_0_m_axis_rx [get_bd_intf_pins temac_support_0/rx_axis_mac] [get_bd_intf_pins tri_mode_ethernet_mac_0/m_axis_rx]
  connect_bd_intf_net -intf_net tri_mode_ethernet_mac_0_mdio_external [get_bd_intf_ports mdio_io] [get_bd_intf_pins tri_mode_ethernet_mac_0/mdio_external]
  connect_bd_intf_net -intf_net tri_mode_ethernet_mac_0_rgmii [get_bd_intf_ports rgmii] [get_bd_intf_pins tri_mode_ethernet_mac_0/rgmii]
  connect_bd_intf_net -intf_net udp_ip_stack_0_mac_tx [get_bd_intf_pins temac_support_0/tx_axis] [get_bd_intf_pins udp_ip_stack_0/mac_tx]
  connect_bd_intf_net -intf_net udp_ip_stack_0_udp_rx [get_bd_intf_pins udp_ip_stack_0/udp_rx] [get_bd_intf_pins uft_stack_0/udp_rx]
  connect_bd_intf_net -intf_net uft_stack_0_axi_master_burst_rx [get_bd_intf_pins axi_master_burst_1/axi_master_burst] [get_bd_intf_pins uft_stack_0/axi_master_burst_rx]
  connect_bd_intf_net -intf_net uft_stack_0_axi_master_burst_tx [get_bd_intf_pins axi_master_burst_0/axi_master_burst] [get_bd_intf_pins uft_stack_0/axi_master_burst_tx]
  connect_bd_intf_net -intf_net uft_stack_0_udp_rx_ctrl [get_bd_intf_pins udp_ip_stack_0/udp_rx_ctrl] [get_bd_intf_pins uft_stack_0/udp_rx_ctrl]
  connect_bd_intf_net -intf_net uft_stack_0_udp_tx [get_bd_intf_pins udp_ip_stack_0/udp_tx] [get_bd_intf_pins uft_stack_0/udp_tx]
  connect_bd_intf_net -intf_net uft_stack_0_udp_tx_ctrl [get_bd_intf_pins udp_ip_stack_0/udp_tx_ctrl] [get_bd_intf_pins uft_stack_0/udp_tx_ctrl]

  # Create port connections
  connect_bd_net -net Net [get_bd_pins udp_ip_stack_0/our_ip_address] [get_bd_pins uft_stack_0/our_ip_address]
  connect_bd_net -net Net1 [get_bd_pins udp_ip_stack_0/our_mac_address] [get_bd_pins uft_stack_0/our_mac_address]
  connect_bd_net -net SW4_1 [get_bd_ports SW4] [get_bd_pins debounce_0/button]
  connect_bd_net -net axi_gpio_0_gpio_io_o [get_bd_pins axi_gpio_0/gpio_io_o] [get_bd_pins uft_stack_0/tx_data_size]
  connect_bd_net -net clk_in_n_1 [get_bd_ports clk_in_n] [get_bd_pins temac_support_0/clk_in_n]
  connect_bd_net -net clk_in_p_1 [get_bd_ports clk_in_p] [get_bd_pins temac_support_0/clk_in_p]
  connect_bd_net -net debounce_0_result [get_bd_pins debounce_0/result] [get_bd_pins impulse_generator_0/enable]
  connect_bd_net -net impulse_generator_0_impulse [get_bd_pins controller_top_0/ap_start] [get_bd_pins impulse_generator_0/impulse] [get_bd_pins uft_stack_0/tx_start]
  connect_bd_net -net reset_1 [get_bd_ports reset] [get_bd_pins rst_temac_support_0_125M/ext_reset_in] [get_bd_pins temac_support_0/glbl_rst]
  connect_bd_net -net rst_temac_support_0_125M_interconnect_aresetn [get_bd_pins axi_mem_intercon/ARESETN] [get_bd_pins rst_temac_support_0_125M/interconnect_aresetn]
  connect_bd_net -net rst_temac_support_0_125M_peripheral_aresetn [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins axi_gpio_0/s_axi_aresetn] [get_bd_pins axi_master_burst_0/m_axi_aresetn] [get_bd_pins axi_master_burst_1/m_axi_aresetn] [get_bd_pins axi_mem_intercon/M00_ARESETN] [get_bd_pins axi_mem_intercon/M01_ARESETN] [get_bd_pins axi_mem_intercon/S00_ARESETN] [get_bd_pins axi_mem_intercon/S01_ARESETN] [get_bd_pins axi_mem_intercon/S02_ARESETN] [get_bd_pins axi_mem_intercon/S03_ARESETN] [get_bd_pins controller_top_0/ap_rst_n] [get_bd_pins jtag_axi_0/aresetn] [get_bd_pins rst_temac_support_0_125M/peripheral_aresetn] [get_bd_pins stream_dummy_top_0/ap_rst_n] [get_bd_pins temac_support_0/axi_tresetn] [get_bd_pins uft_stack_0/rst_n]
  connect_bd_net -net rst_temac_support_0_125M_peripheral_reset [get_bd_pins debounce_0/rst] [get_bd_pins impulse_generator_0/rst] [get_bd_pins rst_temac_support_0_125M/peripheral_reset] [get_bd_pins udp_ip_stack_0/reset]
  connect_bd_net -net speed_1 [get_bd_ports speed] [get_bd_pins temac_support_0/speed]
  connect_bd_net -net temac_support_0_glbl_rstn [get_bd_pins temac_support_0/glbl_rstn] [get_bd_pins tri_mode_ethernet_mac_0/glbl_rstn]
  connect_bd_net -net temac_support_0_gtx_clk [get_bd_pins temac_support_0/gtx_clk] [get_bd_pins tri_mode_ethernet_mac_0/gtx_clk]
  connect_bd_net -net temac_support_0_gtx_clk90 [get_bd_pins temac_support_0/gtx_clk90] [get_bd_pins tri_mode_ethernet_mac_0/gtx_clk90]
  connect_bd_net -net temac_support_0_gtx_clk_bufg_out [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_gpio_0/s_axi_aclk] [get_bd_pins axi_master_burst_0/m_axi_aclk] [get_bd_pins axi_master_burst_1/m_axi_aclk] [get_bd_pins axi_mem_intercon/ACLK] [get_bd_pins axi_mem_intercon/M00_ACLK] [get_bd_pins axi_mem_intercon/M01_ACLK] [get_bd_pins axi_mem_intercon/S00_ACLK] [get_bd_pins axi_mem_intercon/S01_ACLK] [get_bd_pins axi_mem_intercon/S02_ACLK] [get_bd_pins axi_mem_intercon/S03_ACLK] [get_bd_pins controller_top_0/ap_clk] [get_bd_pins debounce_0/clk] [get_bd_pins impulse_generator_0/clk] [get_bd_pins jtag_axi_0/aclk] [get_bd_pins rst_temac_support_0_125M/slowest_sync_clk] [get_bd_pins stream_dummy_top_0/ap_clk] [get_bd_pins temac_support_0/axi_tclk] [get_bd_pins temac_support_0/gtx_clk_bufg_out] [get_bd_pins udp_ip_stack_0/rx_clk] [get_bd_pins udp_ip_stack_0/tx_clk] [get_bd_pins uft_stack_0/clk]
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
  connect_bd_net -net uft_stack_0_tx_ready [get_bd_ports led0] [get_bd_pins uft_stack_0/tx_ready]
  connect_bd_net -net update_speed_1 [get_bd_ports update_speed] [get_bd_pins temac_support_0/update_speed]

  # Create address segments
  create_bd_addr_seg -range 0x00080000 -offset 0x00000000 [get_bd_addr_spaces axi_master_burst_0/m_axi] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] SEG_axi_bram_ctrl_0_Mem0
  create_bd_addr_seg -range 0x00001000 -offset 0x40000000 [get_bd_addr_spaces axi_master_burst_0/m_axi] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] SEG_axi_gpio_0_Reg
  create_bd_addr_seg -range 0x00080000 -offset 0x00000000 [get_bd_addr_spaces axi_master_burst_1/m_axi] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] SEG_axi_bram_ctrl_0_Mem0
  create_bd_addr_seg -range 0x00001000 -offset 0x40000000 [get_bd_addr_spaces axi_master_burst_1/m_axi] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] SEG_axi_gpio_0_Reg
  create_bd_addr_seg -range 0x00080000 -offset 0x00000000 [get_bd_addr_spaces controller_top_0/Data_m_axi_memp] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] SEG_axi_bram_ctrl_0_Mem0
  create_bd_addr_seg -range 0x00080000 -offset 0x00000000 [get_bd_addr_spaces jtag_axi_0/Data] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] SEG_axi_bram_ctrl_0_Mem0
  create_bd_addr_seg -range 0x00001000 -offset 0x40000000 [get_bd_addr_spaces jtag_axi_0/Data] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] SEG_axi_gpio_0_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x00000000 [get_bd_addr_spaces temac_support_0/s_axi] [get_bd_addr_segs tri_mode_ethernet_mac_0/s_axi/Reg] SEG_tri_mode_ethernet_mac_0_Reg

  # Exclude Address Segments
  create_bd_addr_seg -range 0x00001000 -offset 0x40000000 [get_bd_addr_spaces controller_top_0/Data_m_axi_memp] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] SEG_axi_gpio_0_Reg
  exclude_bd_addr_seg [get_bd_addr_segs controller_top_0/Data_m_axi_memp/SEG_axi_gpio_0_Reg]



regenerate_bd_layout
