
  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_0 ]

  # Create instance: axi_smc, and set properties
  set axi_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc ]
  set_property -dict [ list \
   CONFIG.NUM_MI {3} \
   CONFIG.NUM_SI {2} \
 ] $axi_smc

  # Create instance: blk_mem_gen_0, and set properties
  set blk_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0 ]
  set_property -dict [ list \
   CONFIG.EN_SAFETY_CKT {false} \
   CONFIG.Enable_B {Use_ENB_Pin} \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.Port_B_Clock {100} \
   CONFIG.Port_B_Enable_Rate {100} \
   CONFIG.Port_B_Write_Rate {50} \
   CONFIG.Use_RSTB_Pin {true} \
 ] $blk_mem_gen_0

  # Create instance: clk_wiz, and set properties
  set clk_wiz [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:5.4 clk_wiz ]
  set_property -dict [ list \
   CONFIG.CLKIN1_JITTER_PS {50.0} \
   CONFIG.CLKIN2_JITTER_PS {100.0} \
   CONFIG.CLKOUT1_JITTER {107.523} \
   CONFIG.CLKOUT1_PHASE_ERROR {89.971} \
   CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {125} \
   CONFIG.MMCM_CLKFBOUT_MULT_F {5.000} \
   CONFIG.MMCM_CLKIN1_PERIOD {5.000} \
   CONFIG.MMCM_CLKIN2_PERIOD {10.0} \
   CONFIG.MMCM_CLKOUT0_DIVIDE_F {8.000} \
   CONFIG.MMCM_DIVCLK_DIVIDE {1} \
   CONFIG.PRIM_IN_FREQ {200.000} \
   CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} \
   CONFIG.SECONDARY_SOURCE {Single_ended_clock_capable_pin} \
   CONFIG.USE_INCLK_SWITCHOVER {false} \
 ] $clk_wiz

  # Create instance: controller_top_0, and set properties
  set controller_top_0 [ create_bd_cell -type ip -vlnv ime:diip:controller_top:0.2 controller_top_0 ]

  # Create instance: jtag_axi_0, and set properties
  set jtag_axi_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:jtag_axi:1.2 jtag_axi_0 ]

  # Create instance: rst_clk_wiz_100M, and set properties
  set rst_clk_wiz_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_100M ]

  # Create instance: system_ila_0, and set properties
  set system_ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.1 system_ila_0 ]
  set_property -dict [ list \
   CONFIG.C_MON_TYPE {MIX} \
   CONFIG.C_NUM_MONITOR_SLOTS {3} \
   CONFIG.C_NUM_OF_PROBES {1} \
   CONFIG.C_PROBE0_TYPE {0} \
   CONFIG.C_SLOT_0_APC_EN {0} \
   CONFIG.C_SLOT_0_AXI_DATA_SEL {1} \
   CONFIG.C_SLOT_0_AXI_TRIG_SEL {1} \
   CONFIG.C_SLOT_0_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
   CONFIG.C_SLOT_1_APC_EN {0} \
   CONFIG.C_SLOT_1_AXI_DATA_SEL {1} \
   CONFIG.C_SLOT_1_AXI_TRIG_SEL {1} \
   CONFIG.C_SLOT_1_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
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
 ] $system_ila_0

  # Create instance: wallis_0, and set properties
  set wallis_0 [ create_bd_cell -type ip -vlnv ime:diip:wallis:0.1 wallis_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_smc_M00_AXI [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] [get_bd_intf_pins axi_smc/M00_AXI]
  connect_bd_intf_net -intf_net axi_smc_M01_AXI [get_bd_intf_pins axi_smc/M01_AXI] [get_bd_intf_pins wallis_0/s_axi_AXILiteS]
  connect_bd_intf_net -intf_net axi_smc_M02_AXI [get_bd_intf_pins axi_smc/M02_AXI] [get_bd_intf_pins wallis_0/s_axi_SCALAR_BUS]
  connect_bd_intf_net -intf_net controller_top_0_m_axi_memp [get_bd_intf_pins axi_smc/S00_AXI] [get_bd_intf_pins controller_top_0/m_axi_memp]
connect_bd_intf_net -intf_net [get_bd_intf_nets controller_top_0_m_axi_memp] [get_bd_intf_pins axi_smc/S00_AXI] [get_bd_intf_pins system_ila_0/SLOT_2_AXI]
  set_property -dict [ list \
HDL_ATTRIBUTE.DEBUG {true} \
 ] [get_bd_intf_nets controller_top_0_m_axi_memp]
  connect_bd_intf_net -intf_net controller_top_0_outData [get_bd_intf_pins controller_top_0/outData] [get_bd_intf_pins wallis_0/inData]
connect_bd_intf_net -intf_net [get_bd_intf_nets controller_top_0_outData] [get_bd_intf_pins system_ila_0/SLOT_1_AXIS] [get_bd_intf_pins wallis_0/inData]
  set_property -dict [ list \
HDL_ATTRIBUTE.DEBUG {true} \
 ] [get_bd_intf_nets controller_top_0_outData]
  connect_bd_intf_net -intf_net jtag_axi_0_M_AXI [get_bd_intf_pins axi_smc/S01_AXI] [get_bd_intf_pins jtag_axi_0/M_AXI]
  connect_bd_intf_net -intf_net wallis_0_outData [get_bd_intf_pins controller_top_0/inData] [get_bd_intf_pins wallis_0/outData]
connect_bd_intf_net -intf_net [get_bd_intf_nets wallis_0_outData] [get_bd_intf_pins controller_top_0/inData] [get_bd_intf_pins system_ila_0/SLOT_0_AXIS]
  set_property -dict [ list \
HDL_ATTRIBUTE.DEBUG {true} \
 ] [get_bd_intf_nets wallis_0_outData]

  # Create port connections
  connect_bd_net -net SW5_1 [get_bd_ports SW5] [get_bd_pins controller_top_0/rx_done_V] [get_bd_pins system_ila_0/probe0]
  set_property -dict [ list \
HDL_ATTRIBUTE.DEBUG {true} \
 ] [get_bd_nets SW5_1]
  connect_bd_net -net clk_in_n_1 [get_bd_ports clk_in_n] [get_bd_pins clk_wiz/clk_in1_n]
  connect_bd_net -net clk_in_p_1 [get_bd_ports clk_in_p] [get_bd_pins clk_wiz/clk_in1_p]
  connect_bd_net -net clk_wiz_clk_out1 [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_smc/aclk] [get_bd_pins clk_wiz/clk_out1] [get_bd_pins controller_top_0/ap_clk] [get_bd_pins jtag_axi_0/aclk] [get_bd_pins rst_clk_wiz_100M/slowest_sync_clk] [get_bd_pins system_ila_0/clk] [get_bd_pins wallis_0/ap_clk]
  connect_bd_net -net clk_wiz_locked [get_bd_pins clk_wiz/locked] [get_bd_pins rst_clk_wiz_100M/dcm_locked]
  connect_bd_net -net reset_1 [get_bd_ports reset] [get_bd_pins clk_wiz/reset] [get_bd_pins rst_clk_wiz_100M/ext_reset_in]
  connect_bd_net -net rst_clk_wiz_100M_peripheral_aresetn [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins axi_smc/aresetn] [get_bd_pins controller_top_0/ap_rst_n] [get_bd_pins jtag_axi_0/aresetn] [get_bd_pins rst_clk_wiz_100M/peripheral_aresetn] [get_bd_pins system_ila_0/resetn] [get_bd_pins wallis_0/ap_rst_n]

  # Create address segments
  create_bd_addr_seg -range 0x00008000 -offset 0x00000000 [get_bd_addr_spaces controller_top_0/Data_m_axi_memp] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] SEG_axi_bram_ctrl_0_Mem0
  create_bd_addr_seg -range 0x00008000 -offset 0x00000000 [get_bd_addr_spaces jtag_axi_0/Data] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] SEG_axi_bram_ctrl_0_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x44A00000 [get_bd_addr_spaces jtag_axi_0/Data] [get_bd_addr_segs wallis_0/s_axi_AXILiteS/Reg] SEG_wallis_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x44A10000 [get_bd_addr_spaces jtag_axi_0/Data] [get_bd_addr_segs wallis_0/s_axi_SCALAR_BUS/Reg] SEG_wallis_0_Reg3

  # Exclude Address Segments
  create_bd_addr_seg -range 0x00010000 -offset 0x44A00000 [get_bd_addr_spaces controller_top_0/Data_m_axi_memp] [get_bd_addr_segs wallis_0/s_axi_AXILiteS/Reg] SEG_wallis_0_Reg
  exclude_bd_addr_seg [get_bd_addr_segs controller_top_0/Data_m_axi_memp/SEG_wallis_0_Reg]

  create_bd_addr_seg -range 0x00010000 -offset 0x44A10000 [get_bd_addr_spaces controller_top_0/Data_m_axi_memp] [get_bd_addr_segs wallis_0/s_axi_SCALAR_BUS/Reg] SEG_wallis_0_Reg1
  exclude_bd_addr_seg [get_bd_addr_segs controller_top_0/Data_m_axi_memp/SEG_wallis_0_Reg1]

