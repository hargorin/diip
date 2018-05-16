
################################################################
# This is a generated script based on design: system
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2017.3
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source system_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7a200tfbg676-2
   set_property BOARD_PART xilinx.com:ac701:part0:1.3 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name system

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:axi_bram_ctrl:4.0\
xilinx.com:ip:axi_gpio:2.0\
ime:diip:axi_master_burst:2.1\
xilinx.com:ip:blk_mem_gen:8.4\
ime:diip:debounce:1.0\
ime:diip:impulse_generator:1.0\
xilinx.com:ip:jtag_axi:1.2\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:system_ila:1.1\
ime:diip:temac_support:1.0\
xilinx.com:ip:tri_mode_ethernet_mac:9.0\
ime:diip:udp_ip_stack:1.0\
ime:diip:uft_stack:1.1\
"

   set list_ips_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_msg_id "BD_TCL-1003" "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set mdio_io [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:mdio_io:1.0 mdio_io ]
  set rgmii [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:rgmii_rtl:1.0 rgmii ]

  # Create ports
  set SW4 [ create_bd_port -dir I SW4 ]
  set clk_in_n [ create_bd_port -dir I clk_in_n ]
  set clk_in_p [ create_bd_port -dir I clk_in_p ]
  set led0 [ create_bd_port -dir O led0 ]
  set phy_resetn [ create_bd_port -dir O -type rst phy_resetn ]
  set reset [ create_bd_port -dir I -type rst reset ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $reset
  set speed [ create_bd_port -dir I -from 1 -to 0 speed ]
  set update_speed [ create_bd_port -dir I update_speed ]

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
   CONFIG.NUM_SI {3} \
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

  # Create instance: system_ila_0, and set properties
  set system_ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.1 system_ila_0 ]
  set_property -dict [ list \
   CONFIG.C_BRAM_CNT {43} \
   CONFIG.C_DATA_DEPTH {4096} \
   CONFIG.C_MON_TYPE {MIX} \
   CONFIG.C_NUM_MONITOR_SLOTS {2} \
   CONFIG.C_NUM_OF_PROBES {3} \
   CONFIG.C_PROBE0_TYPE {0} \
   CONFIG.C_PROBE1_TYPE {0} \
   CONFIG.C_PROBE2_TYPE {0} \
   CONFIG.C_SLOT {1} \
   CONFIG.C_SLOT_0_INTF_TYPE {Xilinx:user:axi_master_burst_rtl:1.0} \
   CONFIG.C_SLOT_0_TYPE {1} \
   CONFIG.C_SLOT_1_INTF_TYPE {Xilinx:user:udp_tx_ctrl_rtl:1.0} \
   CONFIG.C_SLOT_1_TYPE {1} \
 ] $system_ila_0

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
  connect_bd_intf_net -intf_net jtag_axi_0_M_AXI [get_bd_intf_pins axi_mem_intercon/S00_AXI] [get_bd_intf_pins jtag_axi_0/M_AXI]
  connect_bd_intf_net -intf_net temac_support_0_rx_axis [get_bd_intf_pins temac_support_0/rx_axis] [get_bd_intf_pins udp_ip_stack_0/mac_rx]
  connect_bd_intf_net -intf_net temac_support_0_s_axi [get_bd_intf_pins temac_support_0/s_axi] [get_bd_intf_pins tri_mode_ethernet_mac_0/s_axi]
  connect_bd_intf_net -intf_net temac_support_0_tx_axis_mac [get_bd_intf_pins temac_support_0/tx_axis_mac] [get_bd_intf_pins tri_mode_ethernet_mac_0/s_axis_tx]
  connect_bd_intf_net -intf_net tri_mode_ethernet_mac_0_m_axis_rx [get_bd_intf_pins temac_support_0/rx_axis_mac] [get_bd_intf_pins tri_mode_ethernet_mac_0/m_axis_rx]
  connect_bd_intf_net -intf_net tri_mode_ethernet_mac_0_mdio_external [get_bd_intf_ports mdio_io] [get_bd_intf_pins tri_mode_ethernet_mac_0/mdio_external]
  connect_bd_intf_net -intf_net tri_mode_ethernet_mac_0_rgmii [get_bd_intf_ports rgmii] [get_bd_intf_pins tri_mode_ethernet_mac_0/rgmii]
  connect_bd_intf_net -intf_net udp_ip_stack_0_mac_tx [get_bd_intf_pins temac_support_0/tx_axis] [get_bd_intf_pins udp_ip_stack_0/mac_tx]
  connect_bd_intf_net -intf_net udp_ip_stack_0_udp_rx [get_bd_intf_pins udp_ip_stack_0/udp_rx] [get_bd_intf_pins uft_stack_0/udp_rx]
  connect_bd_intf_net -intf_net uft_stack_0_axi_master_burst_rx [get_bd_intf_pins axi_master_burst_1/axi_master_burst] [get_bd_intf_pins uft_stack_0/axi_master_burst_rx]
connect_bd_intf_net -intf_net [get_bd_intf_nets uft_stack_0_axi_master_burst_rx] [get_bd_intf_pins axi_master_burst_1/axi_master_burst] [get_bd_intf_pins system_ila_0/SLOT_0_AXI_MASTER_BURST]
  set_property -dict [ list \
HDL_ATTRIBUTE.DEBUG {true} \
 ] [get_bd_intf_nets uft_stack_0_axi_master_burst_rx]
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
  connect_bd_net -net impulse_generator_0_impulse [get_bd_pins impulse_generator_0/impulse] [get_bd_pins system_ila_0/probe0] [get_bd_pins uft_stack_0/tx_start]
  set_property -dict [ list \
HDL_ATTRIBUTE.DEBUG {true} \
 ] [get_bd_nets impulse_generator_0_impulse]
  connect_bd_net -net reset_1 [get_bd_ports reset] [get_bd_pins rst_temac_support_0_125M/ext_reset_in] [get_bd_pins temac_support_0/glbl_rst]
  connect_bd_net -net rst_temac_support_0_125M_interconnect_aresetn [get_bd_pins axi_mem_intercon/ARESETN] [get_bd_pins rst_temac_support_0_125M/interconnect_aresetn] [get_bd_pins system_ila_0/probe1]
  set_property -dict [ list \
HDL_ATTRIBUTE.DEBUG {true} \
 ] [get_bd_nets rst_temac_support_0_125M_interconnect_aresetn]
  connect_bd_net -net rst_temac_support_0_125M_peripheral_aresetn [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins axi_gpio_0/s_axi_aresetn] [get_bd_pins axi_master_burst_0/m_axi_aresetn] [get_bd_pins axi_master_burst_1/m_axi_aresetn] [get_bd_pins axi_mem_intercon/M00_ARESETN] [get_bd_pins axi_mem_intercon/M01_ARESETN] [get_bd_pins axi_mem_intercon/S00_ARESETN] [get_bd_pins axi_mem_intercon/S01_ARESETN] [get_bd_pins axi_mem_intercon/S02_ARESETN] [get_bd_pins jtag_axi_0/aresetn] [get_bd_pins rst_temac_support_0_125M/peripheral_aresetn] [get_bd_pins system_ila_0/probe2] [get_bd_pins temac_support_0/axi_tresetn] [get_bd_pins uft_stack_0/rst_n]
  set_property -dict [ list \
HDL_ATTRIBUTE.DEBUG {true} \
 ] [get_bd_nets rst_temac_support_0_125M_peripheral_aresetn]
  connect_bd_net -net rst_temac_support_0_125M_peripheral_reset [get_bd_pins debounce_0/rst] [get_bd_pins impulse_generator_0/rst] [get_bd_pins rst_temac_support_0_125M/peripheral_reset] [get_bd_pins udp_ip_stack_0/reset]
  connect_bd_net -net speed_1 [get_bd_ports speed] [get_bd_pins temac_support_0/speed]
  connect_bd_net -net temac_support_0_glbl_rstn [get_bd_pins temac_support_0/glbl_rstn] [get_bd_pins tri_mode_ethernet_mac_0/glbl_rstn]
  connect_bd_net -net temac_support_0_gtx_clk [get_bd_pins temac_support_0/gtx_clk] [get_bd_pins tri_mode_ethernet_mac_0/gtx_clk]
  connect_bd_net -net temac_support_0_gtx_clk90 [get_bd_pins temac_support_0/gtx_clk90] [get_bd_pins tri_mode_ethernet_mac_0/gtx_clk90]
  connect_bd_net -net temac_support_0_gtx_clk_bufg_out [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_gpio_0/s_axi_aclk] [get_bd_pins axi_master_burst_0/m_axi_aclk] [get_bd_pins axi_master_burst_1/m_axi_aclk] [get_bd_pins axi_mem_intercon/ACLK] [get_bd_pins axi_mem_intercon/M00_ACLK] [get_bd_pins axi_mem_intercon/M01_ACLK] [get_bd_pins axi_mem_intercon/S00_ACLK] [get_bd_pins axi_mem_intercon/S01_ACLK] [get_bd_pins axi_mem_intercon/S02_ACLK] [get_bd_pins debounce_0/clk] [get_bd_pins impulse_generator_0/clk] [get_bd_pins jtag_axi_0/aclk] [get_bd_pins rst_temac_support_0_125M/slowest_sync_clk] [get_bd_pins system_ila_0/clk] [get_bd_pins temac_support_0/axi_tclk] [get_bd_pins temac_support_0/gtx_clk_bufg_out] [get_bd_pins udp_ip_stack_0/rx_clk] [get_bd_pins udp_ip_stack_0/tx_clk] [get_bd_pins uft_stack_0/clk]
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
  create_bd_addr_seg -range 0x00080000 -offset 0x08000000 [get_bd_addr_spaces axi_master_burst_0/m_axi] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] SEG_axi_bram_ctrl_0_Mem0
  create_bd_addr_seg -range 0x00001000 -offset 0x40000000 [get_bd_addr_spaces axi_master_burst_0/m_axi] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] SEG_axi_gpio_0_Reg
  create_bd_addr_seg -range 0x00080000 -offset 0x08000000 [get_bd_addr_spaces axi_master_burst_1/m_axi] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] SEG_axi_bram_ctrl_0_Mem0
  create_bd_addr_seg -range 0x00001000 -offset 0x40000000 [get_bd_addr_spaces axi_master_burst_1/m_axi] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] SEG_axi_gpio_0_Reg
  create_bd_addr_seg -range 0x00080000 -offset 0x08000000 [get_bd_addr_spaces jtag_axi_0/Data] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] SEG_axi_bram_ctrl_0_Mem0
  create_bd_addr_seg -range 0x00001000 -offset 0x40000000 [get_bd_addr_spaces jtag_axi_0/Data] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] SEG_axi_gpio_0_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x00000000 [get_bd_addr_spaces temac_support_0/s_axi] [get_bd_addr_segs tri_mode_ethernet_mac_0/s_axi/Reg] SEG_tri_mode_ethernet_mac_0_Reg


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


