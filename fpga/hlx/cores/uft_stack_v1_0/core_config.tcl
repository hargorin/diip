
# Display name of the core
set display_name {UFT Stack}

# Set top module
set_property top uft_top_wrap [current_fileset]

# set core
set core [ipx::current_core]

# set core properties
set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $display_name $core
set_property VERSION 1.3 $core

# Set Core Parameters
# proc core_parameter {name display_name description} defined in core.tcl
core_parameter INCOMMING_PORT {INCOMMING_PORT} {Listen for UFT Packages only on this port}
core_parameter FIFO_DEPTH {FIFO_DEPTH} {Rx/Tx Fifo size in words, default 366}

core_parameter C_M_AXI_ADDR_WIDTH {C_M_AXI_ADDR_WIDTH} {Master AXI Memory Map Address Width (bits)}
core_parameter C_M_AXI_DATA_WIDTH {C_M_AXI_DATA_WIDTH} {Master AXI Memory Map Data Width (bits)}
core_parameter C_MAX_BURST_LEN {C_MAX_BURST_LEN} {Specifies the max number of databeats to use for each AXI MMap transfer by the AXI Master Burst}
core_parameter C_ADDR_PIPE_DEPTH {C_ADDR_PIPE_DEPTH} {Specifies the address pipeline depth for the AXI Master Burst when submitting transfer requests to the AXI4 Read and Write Address Channels.}
core_parameter C_NATIVE_DATA_WIDTH {C_NATIVE_DATA_WIDTH} {Set this equal to desired data bus width needed by IPIC LocalLink Data Channels.}
core_parameter C_LENGTH_WIDTH {C_LENGTH_WIDTH} {Set this to the desired bit width for the ip2bus_mst_length input port required to specify the maximimum transfer byte count needed for any one command by the User logic.}

ipx::add_user_parameter C_FAMILY [ipx::current_core]
ipgui::add_param -name {C_FAMILY} -component [ipx::current_core] -display_name {FPGA FAMILY} -show_label {true} -show_range {true} -widget {}
set_property value artix7 [ipx::get_user_parameters C_FAMILY -of_objects [ipx::current_core]]
core_parameter C_FAMILY {C_FAMILY} {Target FPGA Device Family}

ipx::add_user_parameter c_pkg_simulation [ipx::current_core]
ipgui::add_param -name {c_pkg_simulation} -component [ipx::current_core] -display_name {FPGA FAMILY} -show_label {true} -show_range {true} -widget {}
set_property value false [ipx::get_user_parameters c_pkg_simulation -of_objects [ipx::current_core]]
ipx::add_user_parameter c_pkg_uft_rx_base_addr [ipx::current_core]
ipgui::add_param -name {c_pkg_uft_rx_base_addr} -component [ipx::current_core] -display_name {FPGA FAMILY} -show_label {true} -show_range {true} -widget {}
set_property value {0x08000000} [ipx::get_user_parameters c_pkg_uft_rx_base_addr -of_objects [ipx::current_core]]

core_parameter c_pkg_simulation {c_pkg_simulation} {Set to false for implementation}
core_parameter c_pkg_uft_rx_base_addr {c_pkg_uft_rx_base_addr} {Base address of rx memory}

ipx::add_bus_interface udp_rx_ctrl [ipx::current_core]
set_property abstraction_type_vlnv Xilinx:user:udp_rx_ctrl_rtl:1.0 [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]
set_property bus_type_vlnv Xilinx:user:udp_rx_ctrl:1.0 [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]
set_property display_name udp_rx_ctrl [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]
set_property description udp_rx_ctrl [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]
ipx::add_port_map udp_rx_hdr_dst_port [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]
set_property physical_name udp_rx_hdr_dst_port [ipx::get_port_maps udp_rx_hdr_dst_port -of_objects [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map udp_rx_start [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]
set_property physical_name udp_rx_start [ipx::get_port_maps udp_rx_start -of_objects [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map udp_rx_hdr_data_length [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]
set_property physical_name udp_rx_hdr_data_length [ipx::get_port_maps udp_rx_hdr_data_length -of_objects [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map udp_rx_hdr_src_ip_addr [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]
set_property physical_name udp_rx_hdr_src_ip_addr [ipx::get_port_maps udp_rx_hdr_src_ip_addr -of_objects [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map udp_rx_hdr_is_valid [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]
set_property physical_name udp_rx_hdr_is_valid [ipx::get_port_maps udp_rx_hdr_is_valid -of_objects [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map udp_rx_hdr_src_port [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]
set_property physical_name udp_rx_hdr_src_port [ipx::get_port_maps udp_rx_hdr_src_port -of_objects [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]]
ipx::associate_bus_interfaces -busif udp_rx_ctrl -clock clk [ipx::current_core]

ipx::add_bus_interface udp_tx_ctrl [ipx::current_core]
set_property abstraction_type_vlnv Xilinx:user:udp_tx_ctrl_rtl:1.0 [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]
set_property bus_type_vlnv Xilinx:user:udp_tx_ctrl:1.0 [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]
set_property display_name udp_tx_ctrl [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]
set_property description udp_tx_ctrl [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]
ipx::add_port_map udp_tx_hdr_dst_ip_addr [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]
set_property physical_name udp_tx_hdr_dst_ip_addr [ipx::get_port_maps udp_tx_hdr_dst_ip_addr -of_objects [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map udp_tx_hdr_src_port [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]
set_property physical_name udp_tx_hdr_src_port [ipx::get_port_maps udp_tx_hdr_src_port -of_objects [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map udp_tx_result [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]
set_property physical_name udp_tx_result [ipx::get_port_maps udp_tx_result -of_objects [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map udp_tx_hdr_dst_port [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]
set_property physical_name udp_tx_hdr_dst_port [ipx::get_port_maps udp_tx_hdr_dst_port -of_objects [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map udp_tx_hdr_data_length [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]
set_property physical_name udp_tx_hdr_data_length [ipx::get_port_maps udp_tx_hdr_data_length -of_objects [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map udp_tx_hdr_checksum [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]
set_property physical_name udp_tx_hdr_checksum [ipx::get_port_maps udp_tx_hdr_checksum -of_objects [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map udp_tx_start [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]
set_property physical_name udp_tx_start [ipx::get_port_maps udp_tx_start -of_objects [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]]
ipx::associate_bus_interfaces -busif udp_tx_ctrl -clock clk [ipx::current_core]
