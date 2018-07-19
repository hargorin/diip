
# Display name of the core
set display_name {UFT Stack}

# Set top module
set_property top uft_top [current_fileset]

# set core
set core [ipx::current_core]

# set core properties
set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $display_name $core
set_property VERSION 2.0 $core

# Set Core Parameters
# set_property  ip_repo_paths  /home/noah/git/diip_dev/fpga/hlx/build/cores [current_project]
ipx::add_bus_interface udp_tx_ctrl [ipx::current_core]
set_property abstraction_type_vlnv Xilinx:user:udp_tx_ctrl_rtl:1.0 [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]
set_property bus_type_vlnv Xilinx:user:udp_tx_ctrl:1.0 [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]
set_property display_name udp_tx_ctrl [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]
set_property description {UDP Tx Control signals} [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]
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

ipx::add_bus_interface udp_rx_ctrl [ipx::current_core]
set_property abstraction_type_vlnv Xilinx:user:udp_rx_ctrl_rtl:1.0 [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]
set_property bus_type_vlnv Xilinx:user:udp_rx_ctrl:1.0 [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]
set_property display_name udp_rx_ctrl [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]
set_property description {UDP Rx Control signals} [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]
set_property interface_mode slave [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]
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
