# @Author: Noah Huetter
# @Date:   2017-11-23 08:37:14
# @Last Modified by:   Noah
# @Last Modified time: 2018-04-26 08:19:04
# ================================================================================
# bd_ports.tcl
# 
# Adds the default ports to the block design including
# - rgmii interface
# - mdio io interface
# - clock and reset in
# - switch in
# 
# by Noah Huetter <noahhuetter@gmail.com>
# ================================================================================

# 200 MHz clock input
create_bd_port -dir I clk_in_n
create_bd_port -dir I clk_in_p
# reset
set reset [ create_bd_port -dir I -type rst reset ]
set_property -dict [ list CONFIG.POLARITY {ACTIVE_HIGH} ] $reset

# speed switch
create_bd_port -dir I -from 1 -to 0 speed
create_bd_port -dir I update_speed

# other switch
create_bd_port -dir I SW4
create_bd_port -dir I SW5

# LED
create_bd_port -dir O led0

# Create PHY interface ports
create_bd_port -dir O -type rst phy_resetn
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:mdio_io:1.0 mdio_io
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:rgmii_rtl:1.0 rgmii
