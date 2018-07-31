
  # Create instance: axi_bram, and set properties
  set axi_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram ]

  # Create instance: axi_protocol_converter_0, and set properties
  set axi_protocol_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_protocol_converter:2.1 axi_protocol_converter_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.ID_WIDTH {0} \
   CONFIG.MI_PROTOCOL {AXI4LITE} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.SI_PROTOCOL {AXI4} \
   CONFIG.TRANSLATION_MODE {0} \
 ] $axi_protocol_converter_0

  # Create instance: axi_smc, and set properties
  set axi_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc ]
  set_property -dict [ list \
   CONFIG.NUM_CLKS {2} \
   CONFIG.NUM_SI {4} \
 ] $axi_smc

  # Create instance: blk_mem_gen, and set properties
  set blk_mem_gen [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen ]
  set_property -dict [ list \
   CONFIG.EN_SAFETY_CKT {false} \
   CONFIG.Enable_B {Use_ENB_Pin} \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.Port_B_Clock {100} \
   CONFIG.Port_B_Enable_Rate {100} \
   CONFIG.Port_B_Write_Rate {50} \
   CONFIG.Use_RSTB_Pin {true} \
 ] $blk_mem_gen

  # Create instance: cbus_offset, and set properties
  set cbus_offset [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 cbus_offset ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {32} \
 ] $cbus_offset

  # Create instance: controller_top, and set properties
  set controller_top [ create_bd_cell -type ip -vlnv ime:diip:controller_top:0.4 controller_top ]

  # Create instance: fanout_d0, and set properties
  set fanout_d0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 fanout_d0 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {0} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {4} \
   CONFIG.DOUT_WIDTH {1} \
 ] $fanout_d0

  # Create instance: fanout_d1, and set properties
  set fanout_d1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 fanout_d1 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {1} \
   CONFIG.DIN_TO {1} \
   CONFIG.DIN_WIDTH {4} \
   CONFIG.DOUT_WIDTH {1} \
 ] $fanout_d1

  # Create instance: fanout_d2, and set properties
  set fanout_d2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 fanout_d2 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {2} \
   CONFIG.DIN_TO {2} \
   CONFIG.DIN_WIDTH {4} \
   CONFIG.DOUT_WIDTH {1} \
 ] $fanout_d2

  # Create instance: jtag_axi_data, and set properties
  set jtag_axi_data [ create_bd_cell -type ip -vlnv xilinx.com:ip:jtag_axi:1.2 jtag_axi_data ]

  # Create instance: jtag_axi_wctrl, and set properties
  set jtag_axi_wctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:jtag_axi:1.2 jtag_axi_wctrl ]

  # Create instance: jtag_axi_wctrl_axi_periph, and set properties
  set jtag_axi_wctrl_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 jtag_axi_wctrl_axi_periph ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
 ] $jtag_axi_wctrl_axi_periph

  # Create instance: rst_temac_support, and set properties
  set rst_temac_support [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_temac_support ]
  set_property -dict [ list \
   CONFIG.RESET_BOARD_INTERFACE {reset} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $rst_temac_support

  # Create instance: system_ila_0, and set properties
  set system_ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.1 system_ila_0 ]
  set_property -dict [ list \
   CONFIG.C_BRAM_CNT {28} \
   CONFIG.C_MON_TYPE {MIX} \
   CONFIG.C_NUM_MONITOR_SLOTS {7} \
   CONFIG.C_NUM_OF_PROBES {5} \
   CONFIG.C_SLOT_0_APC_EN {0} \
   CONFIG.C_SLOT_0_AXI_AR_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_AR_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_AW_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_AW_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_B_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_B_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_R_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_R_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_W_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_W_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_INTF_TYPE {xilinx.com:interface:aximm_rtl:1.0} \
   CONFIG.C_SLOT_0_TXN_CNTR_EN {0} \
   CONFIG.C_SLOT_1_APC_EN {0} \
   CONFIG.C_SLOT_1_AXI_AR_SEL_DATA {1} \
   CONFIG.C_SLOT_1_AXI_AR_SEL_TRIG {1} \
   CONFIG.C_SLOT_1_AXI_AW_SEL_DATA {1} \
   CONFIG.C_SLOT_1_AXI_AW_SEL_TRIG {1} \
   CONFIG.C_SLOT_1_AXI_B_SEL_DATA {1} \
   CONFIG.C_SLOT_1_AXI_B_SEL_TRIG {1} \
   CONFIG.C_SLOT_1_AXI_R_SEL_DATA {1} \
   CONFIG.C_SLOT_1_AXI_R_SEL_TRIG {1} \
   CONFIG.C_SLOT_1_AXI_W_SEL_DATA {1} \
   CONFIG.C_SLOT_1_AXI_W_SEL_TRIG {1} \
   CONFIG.C_SLOT_1_INTF_TYPE {xilinx.com:interface:aximm_rtl:1.0} \
   CONFIG.C_SLOT_2_APC_EN {0} \
   CONFIG.C_SLOT_2_AXI_AR_SEL_DATA {1} \
   CONFIG.C_SLOT_2_AXI_AR_SEL_TRIG {1} \
   CONFIG.C_SLOT_2_AXI_AW_SEL_DATA {1} \
   CONFIG.C_SLOT_2_AXI_AW_SEL_TRIG {1} \
   CONFIG.C_SLOT_2_AXI_B_SEL_DATA {1} \
   CONFIG.C_SLOT_2_AXI_B_SEL_TRIG {1} \
   CONFIG.C_SLOT_2_AXI_R_SEL_DATA {1} \
   CONFIG.C_SLOT_2_AXI_R_SEL_TRIG {1} \
   CONFIG.C_SLOT_2_AXI_W_SEL_DATA {1} \
   CONFIG.C_SLOT_2_AXI_W_SEL_TRIG {1} \
   CONFIG.C_SLOT_2_INTF_TYPE {xilinx.com:interface:aximm_rtl:1.0} \
   CONFIG.C_SLOT_5_APC_EN {0} \
   CONFIG.C_SLOT_5_AXI_DATA_SEL {1} \
   CONFIG.C_SLOT_5_AXI_TRIG_SEL {1} \
   CONFIG.C_SLOT_5_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
   CONFIG.C_SLOT_6_APC_EN {0} \
   CONFIG.C_SLOT_6_AXI_DATA_SEL {1} \
   CONFIG.C_SLOT_6_AXI_TRIG_SEL {1} \
   CONFIG.C_SLOT_6_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
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
  set uft_stack [ create_bd_cell -type ip -vlnv ime:diip:uft_stack:1.3 uft_stack ]

  # Create instance: wallis, and set properties
  set wallis [ create_bd_cell -type ip -vlnv ime:diip:wallis:0.2 wallis ]

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_BRAM_PORTA [get_bd_intf_pins axi_bram/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_BRAM_PORTB [get_bd_intf_pins axi_bram/BRAM_PORTB] [get_bd_intf_pins blk_mem_gen/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_protocol_converter_0_M_AXI [get_bd_intf_pins axi_protocol_converter_0/M_AXI] [get_bd_intf_pins uft_stack/s_axi_ctrl]
connect_bd_intf_net -intf_net [get_bd_intf_nets axi_protocol_converter_0_M_AXI] [get_bd_intf_pins axi_protocol_converter_0/M_AXI] [get_bd_intf_pins system_ila_0/SLOT_2_AXI]
  connect_bd_intf_net -intf_net axi_smc_M00_AXI [get_bd_intf_pins axi_bram/S_AXI] [get_bd_intf_pins axi_smc/M00_AXI]
  connect_bd_intf_net -intf_net controller_top_1_m_axi_memp [get_bd_intf_pins axi_smc/S00_AXI] [get_bd_intf_pins controller_top/m_axi_memp]
connect_bd_intf_net -intf_net [get_bd_intf_nets controller_top_1_m_axi_memp] [get_bd_intf_pins axi_smc/S00_AXI] [get_bd_intf_pins system_ila_0/SLOT_1_AXI]
  set_property -dict [ list \
HDL_ATTRIBUTE.DEBUG {true} \
 ] [get_bd_intf_nets controller_top_1_m_axi_memp]
  connect_bd_intf_net -intf_net controller_top_1_outData [get_bd_intf_pins controller_top/outData] [get_bd_intf_pins wallis/inData]
connect_bd_intf_net -intf_net [get_bd_intf_nets controller_top_1_outData] [get_bd_intf_pins system_ila_0/SLOT_5_AXIS] [get_bd_intf_pins wallis/inData]
  set_property -dict [ list \
HDL_ATTRIBUTE.DEBUG {true} \
 ] [get_bd_intf_nets controller_top_1_outData]
  connect_bd_intf_net -intf_net controller_top_m_axi_cbus [get_bd_intf_pins axi_protocol_converter_0/S_AXI] [get_bd_intf_pins controller_top/m_axi_cbus]
connect_bd_intf_net -intf_net [get_bd_intf_nets controller_top_m_axi_cbus] [get_bd_intf_pins axi_protocol_converter_0/S_AXI] [get_bd_intf_pins system_ila_0/SLOT_0_AXI]
  connect_bd_intf_net -intf_net jtag_axi_M_AXI [get_bd_intf_pins axi_smc/S03_AXI] [get_bd_intf_pins jtag_axi_data/M_AXI]
  connect_bd_intf_net -intf_net jtag_axi_wctrl_M_AXI [get_bd_intf_pins jtag_axi_wctrl/M_AXI] [get_bd_intf_pins jtag_axi_wctrl_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net jtag_axi_wctrl_axi_periph_M00_AXI [get_bd_intf_pins jtag_axi_wctrl_axi_periph/M00_AXI] [get_bd_intf_pins wallis/s_axi_ctrl]
  connect_bd_intf_net -intf_net temac_support_rx_axis [get_bd_intf_pins temac_support/rx_axis] [get_bd_intf_pins udp_ip_stack/mac_rx]
  connect_bd_intf_net -intf_net temac_support_s_axi [get_bd_intf_pins temac_support/s_axi] [get_bd_intf_pins tri_mode_ethernet_mac/s_axi]
  connect_bd_intf_net -intf_net temac_support_tx_axis_mac [get_bd_intf_pins temac_support/tx_axis_mac] [get_bd_intf_pins tri_mode_ethernet_mac/s_axis_tx]
  connect_bd_intf_net -intf_net tri_mode_ethernet_mac_m_axis_rx [get_bd_intf_pins temac_support/rx_axis_mac] [get_bd_intf_pins tri_mode_ethernet_mac/m_axis_rx]
  connect_bd_intf_net -intf_net tri_mode_ethernet_mac_mdio_external [get_bd_intf_ports mdio_io] [get_bd_intf_pins tri_mode_ethernet_mac/mdio_external]
  connect_bd_intf_net -intf_net tri_mode_ethernet_mac_rgmii [get_bd_intf_ports rgmii] [get_bd_intf_pins tri_mode_ethernet_mac/rgmii]
  connect_bd_intf_net -intf_net udp_ip_stack_mac_tx [get_bd_intf_pins temac_support/tx_axis] [get_bd_intf_pins udp_ip_stack/mac_tx]
  connect_bd_intf_net -intf_net udp_ip_stack_udp_rx [get_bd_intf_pins udp_ip_stack/udp_rx] [get_bd_intf_pins uft_stack/udp_rx]
  connect_bd_intf_net -intf_net uft_stack_m_axi_rx [get_bd_intf_pins axi_smc/S01_AXI] [get_bd_intf_pins uft_stack/m_axi_rx]
connect_bd_intf_net -intf_net [get_bd_intf_nets uft_stack_m_axi_rx] [get_bd_intf_pins axi_smc/S01_AXI] [get_bd_intf_pins system_ila_0/SLOT_3_AXI]
  connect_bd_intf_net -intf_net uft_stack_m_axi_tx [get_bd_intf_pins axi_smc/S02_AXI] [get_bd_intf_pins uft_stack/m_axi_tx]
connect_bd_intf_net -intf_net [get_bd_intf_nets uft_stack_m_axi_tx] [get_bd_intf_pins axi_smc/S02_AXI] [get_bd_intf_pins system_ila_0/SLOT_4_AXI]
  connect_bd_intf_net -intf_net uft_stack_udp_rx_ctrl [get_bd_intf_pins udp_ip_stack/udp_rx_ctrl] [get_bd_intf_pins uft_stack/udp_rx_ctrl]
  connect_bd_intf_net -intf_net uft_stack_udp_tx [get_bd_intf_pins udp_ip_stack/udp_tx] [get_bd_intf_pins uft_stack/udp_tx]
  connect_bd_intf_net -intf_net uft_stack_udp_tx_ctrl [get_bd_intf_pins udp_ip_stack/udp_tx_ctrl] [get_bd_intf_pins uft_stack/udp_tx_ctrl]
  connect_bd_intf_net -intf_net wallis_outData [get_bd_intf_pins controller_top/inData] [get_bd_intf_pins wallis/outData]
connect_bd_intf_net -intf_net [get_bd_intf_nets wallis_outData] [get_bd_intf_pins controller_top/inData] [get_bd_intf_pins system_ila_0/SLOT_6_AXIS]
  set_property -dict [ list \
HDL_ATTRIBUTE.DEBUG {true} \
 ] [get_bd_intf_nets wallis_outData]

  # Create port connections
  connect_bd_net -net Net [get_bd_pins udp_ip_stack/our_ip_address] [get_bd_pins uft_stack/our_ip_address]
  connect_bd_net -net Net1 [get_bd_pins udp_ip_stack/our_mac_address] [get_bd_pins uft_stack/our_mac_address]
  connect_bd_net -net cbus_offset_dout [get_bd_pins cbus_offset/dout] [get_bd_pins controller_top/cbus_offset]
  connect_bd_net -net clk_in_n_1 [get_bd_ports clk_in_n] [get_bd_pins temac_support/clk_in_n]
  connect_bd_net -net clk_in_p_1 [get_bd_ports clk_in_p] [get_bd_pins temac_support/clk_in_p]
  connect_bd_net -net controller_top_outState_V [get_bd_pins controller_top/outState_V] [get_bd_pins fanout_d0/Din] [get_bd_pins fanout_d1/Din] [get_bd_pins fanout_d2/Din]
  connect_bd_net -net fanout_d0_Dout [get_bd_ports led0] [get_bd_pins fanout_d0/Dout] [get_bd_pins system_ila_0/probe2]
  connect_bd_net -net fanout_d1_Dout [get_bd_ports led1] [get_bd_pins fanout_d1/Dout] [get_bd_pins system_ila_0/probe3]
  connect_bd_net -net fanout_d2_Dout [get_bd_ports led2] [get_bd_pins fanout_d2/Dout] [get_bd_pins system_ila_0/probe4]
  connect_bd_net -net reset_1 [get_bd_ports reset] [get_bd_pins rst_temac_support/ext_reset_in] [get_bd_pins temac_support/glbl_rst]
  connect_bd_net -net rst_temac_support_125M_interconnect_aresetn [get_bd_pins jtag_axi_wctrl_axi_periph/ARESETN] [get_bd_pins rst_temac_support/interconnect_aresetn]
  connect_bd_net -net rst_temac_support_125M_peripheral_aresetn [get_bd_pins axi_bram/s_axi_aresetn] [get_bd_pins axi_protocol_converter_0/aresetn] [get_bd_pins axi_smc/aresetn] [get_bd_pins controller_top/ap_rst_n] [get_bd_pins jtag_axi_data/aresetn] [get_bd_pins jtag_axi_wctrl/aresetn] [get_bd_pins jtag_axi_wctrl_axi_periph/M00_ARESETN] [get_bd_pins jtag_axi_wctrl_axi_periph/S00_ARESETN] [get_bd_pins rst_temac_support/peripheral_aresetn] [get_bd_pins system_ila_0/resetn] [get_bd_pins temac_support/axi_tresetn] [get_bd_pins uft_stack/m_axi_rx_aresetn] [get_bd_pins uft_stack/m_axi_tx_aresetn] [get_bd_pins uft_stack/rst_n] [get_bd_pins uft_stack/s_axi_ctrl_aresetn] [get_bd_pins wallis/ap_rst_n]
  connect_bd_net -net rst_temac_support_peripheral_reset [get_bd_pins rst_temac_support/peripheral_reset] [get_bd_pins udp_ip_stack/reset]
  connect_bd_net -net speed_1 [get_bd_ports speed] [get_bd_pins temac_support/speed]
  connect_bd_net -net temac_support_glbl_rstn [get_bd_pins temac_support/glbl_rstn] [get_bd_pins tri_mode_ethernet_mac/glbl_rstn]
  connect_bd_net -net temac_support_gtx_clk [get_bd_pins temac_support/gtx_clk] [get_bd_pins tri_mode_ethernet_mac/gtx_clk]
  connect_bd_net -net temac_support_gtx_clk90 [get_bd_pins temac_support/gtx_clk90] [get_bd_pins tri_mode_ethernet_mac/gtx_clk90]
  connect_bd_net -net temac_support_gtx_clk_bufg_out [get_bd_pins axi_bram/s_axi_aclk] [get_bd_pins axi_protocol_converter_0/aclk] [get_bd_pins axi_smc/aclk] [get_bd_pins axi_smc/aclk1] [get_bd_pins controller_top/ap_clk] [get_bd_pins jtag_axi_data/aclk] [get_bd_pins jtag_axi_wctrl/aclk] [get_bd_pins jtag_axi_wctrl_axi_periph/ACLK] [get_bd_pins jtag_axi_wctrl_axi_periph/M00_ACLK] [get_bd_pins jtag_axi_wctrl_axi_periph/S00_ACLK] [get_bd_pins rst_temac_support/slowest_sync_clk] [get_bd_pins system_ila_0/clk] [get_bd_pins temac_support/axi_tclk] [get_bd_pins temac_support/gtx_clk_bufg_out] [get_bd_pins udp_ip_stack/rx_clk] [get_bd_pins udp_ip_stack/tx_clk] [get_bd_pins uft_stack/clk] [get_bd_pins uft_stack/m_axi_rx_aclk] [get_bd_pins uft_stack/m_axi_tx_aclk] [get_bd_pins uft_stack/s_axi_ctrl_aclk] [get_bd_pins wallis/ap_clk]
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
  connect_bd_net -net uft_stack_rx_done [get_bd_ports led3] [get_bd_pins controller_top/rx_done_V] [get_bd_pins system_ila_0/probe0] [get_bd_pins uft_stack/rx_done]
  set_property -dict [ list \
HDL_ATTRIBUTE.DEBUG {true} \
 ] [get_bd_nets uft_stack_rx_done]
  connect_bd_net -net uft_stack_tx_ready [get_bd_pins controller_top/tx_ready_V] [get_bd_pins system_ila_0/probe1] [get_bd_pins uft_stack/tx_ready]
  set_property -dict [ list \
HDL_ATTRIBUTE.DEBUG {true} \
 ] [get_bd_nets uft_stack_tx_ready]
  connect_bd_net -net update_speed_1 [get_bd_ports update_speed] [get_bd_pins temac_support/update_speed]

  # Create address segments
  create_bd_addr_seg -range 0x00040000 -offset 0x00000000 [get_bd_addr_spaces controller_top/Data_m_axi_memp] [get_bd_addr_segs axi_bram/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem0
  create_bd_addr_seg -range 0x00001000 -offset 0x00000000 [get_bd_addr_spaces controller_top/Data_m_axi_cbus] [get_bd_addr_segs uft_stack/s_axi_ctrl/reg0] SEG_uft_stack_reg0
  create_bd_addr_seg -range 0x00040000 -offset 0x00000000 [get_bd_addr_spaces jtag_axi_data/Data] [get_bd_addr_segs axi_bram/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem0
  create_bd_addr_seg -range 0x00001000 -offset 0x00000000 [get_bd_addr_spaces jtag_axi_wctrl/Data] [get_bd_addr_segs wallis/s_axi_ctrl/Reg] SEG_wallis_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x00000000 [get_bd_addr_spaces temac_support/s_axi] [get_bd_addr_segs tri_mode_ethernet_mac/s_axi/Reg] SEG_tri_mode_ethernet_mac_Reg
  create_bd_addr_seg -range 0x00040000 -offset 0x00000000 [get_bd_addr_spaces uft_stack/m_axi_rx] [get_bd_addr_segs axi_bram/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem0
  create_bd_addr_seg -range 0x00040000 -offset 0x00000000 [get_bd_addr_spaces uft_stack/m_axi_tx] [get_bd_addr_segs axi_bram/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem0
