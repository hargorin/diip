
# Display name of the core
set display_name {Tri-Mode Ethernet MAC Support}

# set core
set core [ipx::current_core]

# set core properties
set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $display_name $core

# Set top module
set_property top temac_support_top [current_fileset]
# set_property top_file {<top_file_location>} [current_fileset]

# Set Core Parameters
# proc core_parameter {name display_name description} defined in core.tcl

# Define busses
# set bus [ipx::get_bus_interfaces -of_objects $core m_axi]
# set_property NAME M_AXI $bus
# set_property INTERFACE_MODE master $bus

# set bus [ipx::get_bus_interfaces m_axi_aclk]
# set parameter [ipx::get_bus_parameters -of_objects $bus ASSOCIATED_BUSIF]
# set_property VALUE M_AXI $parameter

# bus parameters
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces rx_axis -of_objects [ipx::current_core]]
set_property value 125000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces rx_axis -of_objects [ipx::current_core]]]

ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces rx_axis_mac -of_objects [ipx::current_core]]
set_property value 125000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces rx_axis_mac -of_objects [ipx::current_core]]]

ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces tx_axis -of_objects [ipx::current_core]]
set_property value 125000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces tx_axis -of_objects [ipx::current_core]]]

ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces tx_axis_mac -of_objects [ipx::current_core]]
set_property value 125000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces tx_axis_mac -of_objects [ipx::current_core]]]

ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces s_axi_aclk -of_objects [ipx::current_core]]
set_property value 125000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces s_axi_aclk -of_objects [ipx::current_core]]]

ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces gtx_clk -of_objects [ipx::current_core]]
set_property value 125000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces gtx_clk -of_objects [ipx::current_core]]]

##
## Add gtx_clk_bufg bus interface
##
ipx::add_bus_interface gtx_clk_bufg [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:signal:clock_rtl:1.0 [ipx::get_bus_interfaces gtx_clk_bufg -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:signal:clock:1.0 [ipx::get_bus_interfaces gtx_clk_bufg -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces gtx_clk_bufg -of_objects [ipx::current_core]]
ipx::add_port_map CLK [ipx::get_bus_interfaces gtx_clk_bufg -of_objects [ipx::current_core]]
set_property physical_name gtx_clk_bufg_out [ipx::get_port_maps CLK -of_objects [ipx::get_bus_interfaces gtx_clk_bufg -of_objects [ipx::current_core]]]

ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces gtx_clk_bufg -of_objects [ipx::current_core]]
set_property value 125000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces gtx_clk_bufg -of_objects [ipx::current_core]]]


set_property driver_value 0 [ipx::get_ports rx_statistics_vector -of_objects [ipx::current_core]]
set_property driver_value 0 [ipx::get_ports rx_statistics_valid -of_objects [ipx::current_core]]
set_property driver_value 0 [ipx::get_ports tx_statistics_vector -of_objects [ipx::current_core]]
set_property driver_value 0 [ipx::get_ports tx_statistics_valid -of_objects [ipx::current_core]]
set_property driver_value 0 [ipx::get_ports mac_irq -of_objects [ipx::current_core]]

# clk - bus association
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces rx_mac_aclk -of_objects [ipx::current_core]]
set_property value rx_axis_mac [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces rx_mac_aclk -of_objects [ipx::current_core]]]
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces tx_mac_aclk -of_objects [ipx::current_core]]
set_property value tx_axis_mac [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces tx_mac_aclk -of_objects [ipx::current_core]]]
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces gtx_clk_bufg -of_objects [ipx::current_core]]
set_property value tx_axis:rx_axis [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces gtx_clk_bufg -of_objects [ipx::current_core]]]
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces gtx_clk -of_objects [ipx::current_core]]
set_property value {} [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces gtx_clk -of_objects [ipx::current_core]]]
