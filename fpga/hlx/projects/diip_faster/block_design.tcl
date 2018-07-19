
  # Create instance: diip_controller_0, and set properties
  set diip_controller_0 [ create_bd_cell -type ip -vlnv ime:diip:diip_controller:1.0 diip_controller_0 ]
  set_property -dict [list \
    CONFIG.FIFO_DEPTH {2048} \
    CONFIG.BRAM_SIZE {16384} \
    CONFIG.CACHE_N_LINES {22} \
  ] $diip_controller_0

  # Create instance: rst_temac_support, and set properties
  set rst_temac_support [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_temac_support ]
  set_property -dict [ list \
   CONFIG.RESET_BOARD_INTERFACE {reset} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $rst_temac_support

  # Create instance: system_ila_0, and set properties
  set system_ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.1 system_ila_0 ]
  set_property -dict [ list \
   CONFIG.C_BRAM_CNT {5} \
   CONFIG.C_DATA_DEPTH {4096} \
   CONFIG.C_MON_TYPE {MIX} \
   CONFIG.C_NUM_MONITOR_SLOTS {4} \
   CONFIG.C_NUM_OF_PROBES {1} \
   CONFIG.C_PROBE0_TYPE {0} \
   CONFIG.C_SLOT {1} \
   CONFIG.C_SLOT_0_APC_EN {0} \
   CONFIG.C_SLOT_0_AXI_DATA_SEL {1} \
   CONFIG.C_SLOT_0_AXI_TRIG_SEL {1} \
   CONFIG.C_SLOT_0_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
   CONFIG.C_SLOT_1_APC_EN {0} \
   CONFIG.C_SLOT_1_AXI_DATA_SEL {1} \
   CONFIG.C_SLOT_1_AXI_TRIG_SEL {1} \
   CONFIG.C_SLOT_1_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
   CONFIG.C_SLOT_2_APC_EN {0} \
   CONFIG.C_SLOT_2_AXI_DATA_SEL {1} \
   CONFIG.C_SLOT_2_AXI_TRIG_SEL {1} \
   CONFIG.C_SLOT_2_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
   CONFIG.C_SLOT_3_APC_EN {0} \
   CONFIG.C_SLOT_3_AXI_DATA_SEL {1} \
   CONFIG.C_SLOT_3_AXI_TRIG_SEL {1} \
   CONFIG.C_SLOT_3_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
 ] $system_ila_0

  # Create instance: temac_support, and set properties
  set temac_support [ create_bd_cell -type ip -vlnv ime:diip:temac_support:1.0 temac_support ]

  # Create instance: tri_mode_ethernet_mac, and set properties
  set tri_mode_ethernet_mac [ create_bd_cell -type ip -vlnv xilinx.com:ip:tri_mode_ethernet_mac:9.0 tri_mode_ethernet_mac ]
  set_property -dict [ list \
   CONFIG.ETHERNET_BOARD_INTERFACE {rgmii} \
   CONFIG.Frame_Filter {false} \
   CONFIG.MDIO_BOARD_INTERFACE {mdio_io} \
   CONFIG.Number_of_Table_Entries {0} \
   CONFIG.Physical_Interface {RGMII} \
   CONFIG.Statistics_Counters {false} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $tri_mode_ethernet_mac

  # Create instance: udp_ip_stack, and set properties
  set udp_ip_stack [ create_bd_cell -type ip -vlnv ime:diip:udp_ip_stack:1.0 udp_ip_stack ]

  # Create instance: uft_stack, and set properties
  set uft_stack [ create_bd_cell -type ip -vlnv ime:diip:uft_stack:2.0 uft_stack ]

  # Create instance: wallis_model_0, and set properties
  set wallis_model_0 [ create_bd_cell -type ip -vlnv ime:diip:wallis_model:1.0 wallis_model_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net diip_controller_0_uft_o_axis [get_bd_intf_pins diip_controller_0/uft_o_axis] [get_bd_intf_pins uft_stack/s_axis]
connect_bd_intf_net -intf_net [get_bd_intf_nets diip_controller_0_uft_o_axis] [get_bd_intf_pins system_ila_0/SLOT_1_AXIS] [get_bd_intf_pins uft_stack/s_axis]
  set_property -dict [ list \
HDL_ATTRIBUTE.DEBUG {true} \
 ] [get_bd_intf_nets diip_controller_0_uft_o_axis]
  connect_bd_intf_net -intf_net diip_controller_0_wa_o_axis [get_bd_intf_pins diip_controller_0/wa_o_axis] [get_bd_intf_pins wallis_model_0/i_axis]
connect_bd_intf_net -intf_net [get_bd_intf_nets diip_controller_0_wa_o_axis] [get_bd_intf_pins system_ila_0/SLOT_3_AXIS] [get_bd_intf_pins wallis_model_0/i_axis]
  set_property -dict [ list \
HDL_ATTRIBUTE.DEBUG {true} \
 ] [get_bd_intf_nets diip_controller_0_wa_o_axis]
  connect_bd_intf_net -intf_net temac_support_rx_axis [get_bd_intf_pins temac_support/rx_axis] [get_bd_intf_pins udp_ip_stack/mac_rx]
  connect_bd_intf_net -intf_net temac_support_s_axi [get_bd_intf_pins temac_support/s_axi] [get_bd_intf_pins tri_mode_ethernet_mac/s_axi]
  connect_bd_intf_net -intf_net temac_support_tx_axis_mac [get_bd_intf_pins temac_support/tx_axis_mac] [get_bd_intf_pins tri_mode_ethernet_mac/s_axis_tx]
  connect_bd_intf_net -intf_net tri_mode_ethernet_mac_m_axis_rx [get_bd_intf_pins temac_support/rx_axis_mac] [get_bd_intf_pins tri_mode_ethernet_mac/m_axis_rx]
  connect_bd_intf_net -intf_net tri_mode_ethernet_mac_mdio_external [get_bd_intf_ports mdio_io] [get_bd_intf_pins tri_mode_ethernet_mac/mdio_external]
  connect_bd_intf_net -intf_net tri_mode_ethernet_mac_rgmii [get_bd_intf_ports rgmii] [get_bd_intf_pins tri_mode_ethernet_mac/rgmii]
  connect_bd_intf_net -intf_net udp_ip_stack_mac_tx [get_bd_intf_pins temac_support/tx_axis] [get_bd_intf_pins udp_ip_stack/mac_tx]
  connect_bd_intf_net -intf_net udp_ip_stack_udp_rx [get_bd_intf_pins udp_ip_stack/udp_rx] [get_bd_intf_pins uft_stack/udp_rx]
  connect_bd_intf_net -intf_net uft_stack_m_axis [get_bd_intf_pins diip_controller_0/uft_i_axis] [get_bd_intf_pins uft_stack/m_axis]
connect_bd_intf_net -intf_net [get_bd_intf_nets uft_stack_m_axis] [get_bd_intf_pins system_ila_0/SLOT_0_AXIS] [get_bd_intf_pins uft_stack/m_axis]
  set_property -dict [ list \
HDL_ATTRIBUTE.DEBUG {true} \
 ] [get_bd_intf_nets uft_stack_m_axis]
  connect_bd_intf_net -intf_net uft_stack_udp_rx_ctrl [get_bd_intf_pins udp_ip_stack/udp_rx_ctrl] [get_bd_intf_pins uft_stack/udp_rx_ctrl]
  connect_bd_intf_net -intf_net uft_stack_udp_tx [get_bd_intf_pins udp_ip_stack/udp_tx] [get_bd_intf_pins uft_stack/udp_tx]
  connect_bd_intf_net -intf_net uft_stack_udp_tx_ctrl [get_bd_intf_pins udp_ip_stack/udp_tx_ctrl] [get_bd_intf_pins uft_stack/udp_tx_ctrl]
  connect_bd_intf_net -intf_net wallis_model_0_o_axis [get_bd_intf_pins diip_controller_0/wa_i_axis] [get_bd_intf_pins wallis_model_0/o_axis]
connect_bd_intf_net -intf_net [get_bd_intf_nets wallis_model_0_o_axis] [get_bd_intf_pins system_ila_0/SLOT_2_AXIS] [get_bd_intf_pins wallis_model_0/o_axis]
  set_property -dict [ list \
HDL_ATTRIBUTE.DEBUG {true} \
 ] [get_bd_intf_nets wallis_model_0_o_axis]

  # Create port connections
  connect_bd_net -net Net [get_bd_pins udp_ip_stack/our_ip_address] [get_bd_pins uft_stack/our_ip_address]
  connect_bd_net -net Net1 [get_bd_pins udp_ip_stack/our_mac_address] [get_bd_pins uft_stack/our_mac_address]
  connect_bd_net -net clk_in_n_1 [get_bd_ports clk_in_n] [get_bd_pins temac_support/clk_in_n]
  connect_bd_net -net clk_in_p_1 [get_bd_ports clk_in_p] [get_bd_pins temac_support/clk_in_p]
  connect_bd_net -net diip_controller_0_uft_tx_data_size [get_bd_pins diip_controller_0/uft_tx_data_size] [get_bd_pins uft_stack/tx_data_size]
  connect_bd_net -net diip_controller_0_uft_tx_row_num [get_bd_pins diip_controller_0/uft_tx_row_num] [get_bd_pins uft_stack/tx_row_num]
  connect_bd_net -net diip_controller_0_uft_tx_start [get_bd_pins diip_controller_0/uft_tx_start] [get_bd_pins uft_stack/tx_start]
  connect_bd_net -net diip_controller_0_wa_par_b_gmean [get_bd_pins diip_controller_0/wa_par_b_gmean] [get_bd_pins wallis_model_0/wa_par_b_gmean]
  connect_bd_net -net diip_controller_0_wa_par_bi [get_bd_pins diip_controller_0/wa_par_bi] [get_bd_pins wallis_model_0/wa_par_bi]
  connect_bd_net -net diip_controller_0_wa_par_c [get_bd_pins diip_controller_0/wa_par_c] [get_bd_pins wallis_model_0/wa_par_c]
  connect_bd_net -net diip_controller_0_wa_par_c_gvar [get_bd_pins diip_controller_0/wa_par_c_gvar] [get_bd_pins wallis_model_0/wa_par_c_gvar]
  connect_bd_net -net diip_controller_0_wa_par_ci_gvar [get_bd_pins diip_controller_0/wa_par_ci_gvar] [get_bd_pins wallis_model_0/wa_par_ci_gvar]
  connect_bd_net -net reset_1 [get_bd_ports reset] [get_bd_pins rst_temac_support/ext_reset_in] [get_bd_pins temac_support/glbl_rst]
  connect_bd_net -net rst_temac_support_125M_peripheral_aresetn [get_bd_pins diip_controller_0/rst_n] [get_bd_pins rst_temac_support/peripheral_aresetn] [get_bd_pins system_ila_0/resetn] [get_bd_pins temac_support/axi_tresetn] [get_bd_pins uft_stack/rst_n] [get_bd_pins wallis_model_0/rst_n]
  connect_bd_net -net rst_temac_support_peripheral_reset [get_bd_pins rst_temac_support/peripheral_reset] [get_bd_pins udp_ip_stack/reset]
  connect_bd_net -net speed_1 [get_bd_ports speed] [get_bd_pins temac_support/speed]
  connect_bd_net -net temac_support_glbl_rstn [get_bd_pins temac_support/glbl_rstn] [get_bd_pins tri_mode_ethernet_mac/glbl_rstn]
  connect_bd_net -net temac_support_gtx_clk [get_bd_pins temac_support/gtx_clk] [get_bd_pins tri_mode_ethernet_mac/gtx_clk]
  connect_bd_net -net temac_support_gtx_clk90 [get_bd_pins temac_support/gtx_clk90] [get_bd_pins tri_mode_ethernet_mac/gtx_clk90]
  connect_bd_net -net temac_support_gtx_clk_bufg_out [get_bd_pins diip_controller_0/clk] [get_bd_pins rst_temac_support/slowest_sync_clk] [get_bd_pins system_ila_0/clk] [get_bd_pins temac_support/axi_tclk] [get_bd_pins temac_support/gtx_clk_bufg_out] [get_bd_pins udp_ip_stack/rx_clk] [get_bd_pins udp_ip_stack/tx_clk] [get_bd_pins uft_stack/clk] [get_bd_pins wallis_model_0/clk]
  connect_bd_net -net temac_support_phy_resetn [get_bd_ports phy_resetn] [get_bd_pins temac_support/phy_resetn]
  connect_bd_net -net temac_support_rx_axi_rstn [get_bd_pins temac_support/rx_axi_rstn] [get_bd_pins tri_mode_ethernet_mac/rx_axi_rstn]
  connect_bd_net -net temac_support_s_axi_aclk [get_bd_pins temac_support/s_axi_aclk] [get_bd_pins tri_mode_ethernet_mac/s_axi_aclk]
  connect_bd_net -net temac_support_s_axi_resetn [get_bd_pins temac_support/s_axi_resetn] [get_bd_pins tri_mode_ethernet_mac/s_axi_resetn]
  connect_bd_net -net temac_support_tx_axi_rstn [get_bd_pins temac_support/tx_axi_rstn] [get_bd_pins tri_mode_ethernet_mac/tx_axi_rstn]
  connect_bd_net -net temac_support_tx_ifg_delay [get_bd_pins temac_support/tx_ifg_delay] [get_bd_pins tri_mode_ethernet_mac/tx_ifg_delay]
  connect_bd_net -net tri_mode_ethernet_mac_rx_enable [get_bd_pins temac_support/rx_enable] [get_bd_pins tri_mode_ethernet_mac/rx_enable]
  connect_bd_net -net tri_mode_ethernet_mac_rx_mac_aclk [get_bd_pins temac_support/rx_mac_aclk] [get_bd_pins tri_mode_ethernet_mac/rx_mac_aclk]
  connect_bd_net -net tri_mode_ethernet_mac_rx_reset [get_bd_pins temac_support/rx_reset] [get_bd_pins tri_mode_ethernet_mac/rx_reset]
  connect_bd_net -net tri_mode_ethernet_mac_speedis100 [get_bd_pins temac_support/speedis100] [get_bd_pins tri_mode_ethernet_mac/speedis100]
  connect_bd_net -net tri_mode_ethernet_mac_speedis10100 [get_bd_pins temac_support/speedis10100] [get_bd_pins tri_mode_ethernet_mac/speedis10100]
  connect_bd_net -net tri_mode_ethernet_mac_tx_enable [get_bd_pins temac_support/tx_enable] [get_bd_pins tri_mode_ethernet_mac/tx_enable]
  connect_bd_net -net tri_mode_ethernet_mac_tx_mac_aclk [get_bd_pins temac_support/tx_mac_aclk] [get_bd_pins tri_mode_ethernet_mac/tx_mac_aclk]
  connect_bd_net -net tri_mode_ethernet_mac_tx_reset [get_bd_pins temac_support/tx_reset] [get_bd_pins tri_mode_ethernet_mac/tx_reset]
  connect_bd_net -net uft_stack_rx_done [get_bd_ports led3] [get_bd_pins diip_controller_0/uft_rx_done] [get_bd_pins system_ila_0/probe0] [get_bd_pins uft_stack/rx_done]
  set_property -dict [ list \
HDL_ATTRIBUTE.DEBUG {true} \
 ] [get_bd_nets uft_stack_rx_done]
  connect_bd_net -net uft_stack_rx_row_num [get_bd_pins diip_controller_0/uft_rx_row_num] [get_bd_pins uft_stack/rx_row_num]
  connect_bd_net -net uft_stack_rx_row_num_valid [get_bd_pins diip_controller_0/uft_rx_row_num_valid] [get_bd_pins uft_stack/rx_row_num_valid]
  connect_bd_net -net uft_stack_rx_row_size [get_bd_pins diip_controller_0/uft_rx_row_size] [get_bd_pins uft_stack/rx_row_size]
  connect_bd_net -net uft_stack_rx_row_size_valid [get_bd_pins diip_controller_0/uft_rx_row_size_valid] [get_bd_pins uft_stack/rx_row_size_valid]
  connect_bd_net -net uft_stack_tx_ready [get_bd_pins diip_controller_0/uft_tx_ready] [get_bd_pins uft_stack/tx_ready]
  connect_bd_net -net uft_stack_user_reg0 [get_bd_pins diip_controller_0/uft_user_reg0] [get_bd_pins uft_stack/user_reg0]
  connect_bd_net -net uft_stack_user_reg1 [get_bd_pins diip_controller_0/uft_user_reg1] [get_bd_pins uft_stack/user_reg1]
  connect_bd_net -net uft_stack_user_reg2 [get_bd_pins diip_controller_0/uft_user_reg2] [get_bd_pins uft_stack/user_reg2]
  connect_bd_net -net uft_stack_user_reg3 [get_bd_pins diip_controller_0/uft_user_reg3] [get_bd_pins uft_stack/user_reg3]
  connect_bd_net -net uft_stack_user_reg4 [get_bd_pins diip_controller_0/uft_user_reg4] [get_bd_pins uft_stack/user_reg4]
  connect_bd_net -net uft_stack_user_reg5 [get_bd_pins diip_controller_0/uft_user_reg5] [get_bd_pins uft_stack/user_reg5]
  connect_bd_net -net uft_stack_user_reg6 [get_bd_pins diip_controller_0/uft_user_reg6] [get_bd_pins uft_stack/user_reg6]
  connect_bd_net -net uft_stack_user_reg7 [get_bd_pins diip_controller_0/uft_user_reg7] [get_bd_pins uft_stack/user_reg7]
  connect_bd_net -net update_speed_1 [get_bd_ports update_speed] [get_bd_pins temac_support/update_speed]

  # Create address segments
  create_bd_addr_seg -range 0x00001000 -offset 0x00000000 [get_bd_addr_spaces temac_support/s_axi] [get_bd_addr_segs tri_mode_ethernet_mac/s_axi/Reg] SEG_tri_mode_ethernet_mac_Reg
