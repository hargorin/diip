
# Display name of the core
set display_name {UDP IP Stack}

# Set top module
set_property top UDP_Complete_nomac [current_fileset]

# set core
set core [ipx::current_core]

# set core properties
set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $display_name $core

# Set Core Parameters
# proc core_parameter {name display_name description} defined in core.tcl
core_parameter CLOCK_FREQ {CLOCK_FREQ} {freq of data_in_clk -- needed to timout cntr}
core_parameter ARP_TIMEOUT {ARP_TIMEOUT} {ARP response timeout (s)}
core_parameter ARP_MAX_PKT_TMO {ARP_MAX_PKT_TMO} {# wrong nwk pkts received before set error}
core_parameter MAX_ARP_ENTRIES {MAX_ARP_ENTRIES} {max entries in the ARP store}



# Define busses
# Tx AXI-S
ipx::add_bus_interface udp_tx [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:axis_rtl:1.0 [ipx::get_bus_interfaces udp_tx -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:axis:1.0 [ipx::get_bus_interfaces udp_tx -of_objects [ipx::current_core]]
ipx::add_port_map TDATA [ipx::get_bus_interfaces udp_tx -of_objects [ipx::current_core]]
set_property physical_name udp_txi_data_out [ipx::get_port_maps TDATA -of_objects [ipx::get_bus_interfaces udp_tx -of_objects [ipx::current_core]]]
ipx::add_port_map TLAST [ipx::get_bus_interfaces udp_tx -of_objects [ipx::current_core]]
set_property physical_name udp_txi_data_out_last [ipx::get_port_maps TLAST -of_objects [ipx::get_bus_interfaces udp_tx -of_objects [ipx::current_core]]]
ipx::add_port_map TVALID [ipx::get_bus_interfaces udp_tx -of_objects [ipx::current_core]]
set_property physical_name udp_txi_data_out_valid [ipx::get_port_maps TVALID -of_objects [ipx::get_bus_interfaces udp_tx -of_objects [ipx::current_core]]]
ipx::add_port_map TREADY [ipx::get_bus_interfaces udp_tx -of_objects [ipx::current_core]]
set_property physical_name udp_tx_data_out_ready [ipx::get_port_maps TREADY -of_objects [ipx::get_bus_interfaces udp_tx -of_objects [ipx::current_core]]]

# Rx AXI-S
ipx::add_bus_interface udp_rx [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:axis_rtl:1.0 [ipx::get_bus_interfaces udp_rx -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:axis:1.0 [ipx::get_bus_interfaces udp_rx -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces udp_rx -of_objects [ipx::current_core]]
ipx::add_port_map TDATA [ipx::get_bus_interfaces udp_rx -of_objects [ipx::current_core]]
set_property physical_name udp_rxo_data_in [ipx::get_port_maps TDATA -of_objects [ipx::get_bus_interfaces udp_rx -of_objects [ipx::current_core]]]
ipx::add_port_map TVALID [ipx::get_bus_interfaces udp_rx -of_objects [ipx::current_core]]
set_property physical_name udp_rxo_data_in_valid [ipx::get_port_maps TVALID -of_objects [ipx::get_bus_interfaces udp_rx -of_objects [ipx::current_core]]]
ipx::add_port_map TLAST [ipx::get_bus_interfaces udp_rx -of_objects [ipx::current_core]]
set_property physical_name udp_rxo_data_in_last [ipx::get_port_maps TLAST -of_objects [ipx::get_bus_interfaces udp_rx -of_objects [ipx::current_core]]]


# set bus [ipx::get_bus_interfaces -of_objects $core m_axi]
# set_property NAME M_AXI $bus
# set_property INTERFACE_MODE master $bus

# set bus [ipx::get_bus_interfaces m_axi_aclk]
# set parameter [ipx::get_bus_parameters -of_objects $bus ASSOCIATED_BUSIF]
# set_property VALUE M_AXI $parameter

# AXI  bus clocks
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces mac_rx -of_objects [ipx::current_core]]
set_property value 125000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces mac_rx -of_objects [ipx::current_core]]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces mac_tx -of_objects [ipx::current_core]]
set_property value 125000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces mac_tx -of_objects [ipx::current_core]]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces udp_tx -of_objects [ipx::current_core]]
set_property value 125000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces udp_tx -of_objects [ipx::current_core]]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces udp_rx -of_objects [ipx::current_core]]
set_property value 125000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces udp_rx -of_objects [ipx::current_core]]]

# Fix bus associations
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces rx_clk -of_objects [ipx::current_core]]
set_property value mac_rx [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces rx_clk -of_objects [ipx::current_core]]]
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces tx_clk -of_objects [ipx::current_core]]
set_property value mac_tx [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces tx_clk -of_objects [ipx::current_core]]]