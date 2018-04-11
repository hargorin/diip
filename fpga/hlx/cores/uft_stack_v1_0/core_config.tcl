
# Display name of the core
set display_name {UFT Stack}

# Set top module
set_property top uft_top [current_fileset]

# set core
set core [ipx::current_core]

# set core properties
set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $display_name $core
set_property VERSION 1.1 $core

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


# Define busses
# axi master burst interface
ipx::add_bus_interface axi_master_burst_rx [ipx::current_core]
set bus [ipx::get_bus_interfaces axi_master_burst_rx -of_objects [ipx::current_core]]
set_property abstraction_type_vlnv Xilinx:user:axi_master_burst_rtl:1.0 $bus
set_property bus_type_vlnv Xilinx:user:axi_master_burst_rx:1.0 $bus
set_property interface_mode master $bus
# mapping
ipx::add_port_map bus2ip_mstrd_d $bus
set_property physical_name bus2ip_mstrd_d [ipx::get_port_maps bus2ip_mstrd_d -of_objects $bus]
ipx::add_port_map ip2bus_mstwr_d $bus
set_property physical_name ip2bus_mstwr_d [ipx::get_port_maps ip2bus_mstwr_d -of_objects $bus]
ipx::add_port_map ip2bus_mstwr_src_dsc_n $bus
set_property physical_name ip2bus_mstwr_src_dsc_n [ipx::get_port_maps ip2bus_mstwr_src_dsc_n -of_objects $bus]
ipx::add_port_map bus2ip_mst_cmdack $bus
set_property physical_name bus2ip_mst_cmdack [ipx::get_port_maps bus2ip_mst_cmdack -of_objects $bus]
ipx::add_port_map bus2ip_mstrd_eof_n $bus
set_property physical_name bus2ip_mstrd_eof_n [ipx::get_port_maps bus2ip_mstrd_eof_n -of_objects $bus]
ipx::add_port_map bus2ip_mst_rearbitrate $bus
set_property physical_name bus2ip_mst_rearbitrate [ipx::get_port_maps bus2ip_mst_rearbitrate -of_objects $bus]
ipx::add_port_map bus2ip_mstwr_dst_dsc_n $bus
set_property physical_name bus2ip_mstwr_dst_dsc_n [ipx::get_port_maps bus2ip_mstwr_dst_dsc_n -of_objects $bus]
ipx::add_port_map bus2ip_mst_cmplt $bus
set_property physical_name bus2ip_mst_cmplt [ipx::get_port_maps bus2ip_mst_cmplt -of_objects $bus]
ipx::add_port_map ip2bus_mstwr_src_rdy_n $bus
set_property physical_name ip2bus_mstwr_src_rdy_n [ipx::get_port_maps ip2bus_mstwr_src_rdy_n -of_objects $bus]
ipx::add_port_map ip2bus_mst_length $bus
set_property physical_name ip2bus_mst_length [ipx::get_port_maps ip2bus_mst_length -of_objects $bus]
ipx::add_port_map bus2ip_mstrd_sof_n $bus
set_property physical_name bus2ip_mstrd_sof_n [ipx::get_port_maps bus2ip_mstrd_sof_n -of_objects $bus]
ipx::add_port_map ip2bus_mstrd_req $bus
set_property physical_name ip2bus_mstrd_req [ipx::get_port_maps ip2bus_mstrd_req -of_objects $bus]
ipx::add_port_map bus2ip_mst_cmd_timeout $bus
set_property physical_name bus2ip_mst_cmd_timeout [ipx::get_port_maps bus2ip_mst_cmd_timeout -of_objects $bus]
ipx::add_port_map bus2ip_mstrd_rem $bus
set_property physical_name bus2ip_mstrd_rem [ipx::get_port_maps bus2ip_mstrd_rem -of_objects $bus]
ipx::add_port_map ip2bus_mstwr_rem $bus
set_property physical_name ip2bus_mstwr_rem [ipx::get_port_maps ip2bus_mstwr_rem -of_objects $bus]
ipx::add_port_map ip2bus_mst_addr $bus
set_property physical_name ip2bus_mst_addr [ipx::get_port_maps ip2bus_mst_addr -of_objects $bus]
ipx::add_port_map ip2bus_mstwr_req $bus
set_property physical_name ip2bus_mstwr_req [ipx::get_port_maps ip2bus_mstwr_req -of_objects $bus]
ipx::add_port_map ip2bus_mstwr_sof_n $bus
set_property physical_name ip2bus_mstwr_sof_n [ipx::get_port_maps ip2bus_mstwr_sof_n -of_objects $bus]
ipx::add_port_map bus2ip_mstrd_src_rdy_n $bus
set_property physical_name bus2ip_mstrd_src_rdy_n [ipx::get_port_maps bus2ip_mstrd_src_rdy_n -of_objects $bus]
ipx::add_port_map ip2bus_mst_type $bus
set_property physical_name ip2bus_mst_type [ipx::get_port_maps ip2bus_mst_type -of_objects $bus]
ipx::add_port_map ip2bus_mstrd_dst_rdy_n $bus
set_property physical_name ip2bus_mstrd_dst_rdy_n [ipx::get_port_maps ip2bus_mstrd_dst_rdy_n -of_objects $bus]
ipx::add_port_map bus2ip_mst_error $bus
set_property physical_name bus2ip_mst_error [ipx::get_port_maps bus2ip_mst_error -of_objects $bus]
ipx::add_port_map ip2bus_mstwr_eof_n $bus
set_property physical_name ip2bus_mstwr_eof_n [ipx::get_port_maps ip2bus_mstwr_eof_n -of_objects $bus]
ipx::add_port_map ip2bus_mst_lock $bus
set_property physical_name ip2bus_mst_lock [ipx::get_port_maps ip2bus_mst_lock -of_objects $bus]
ipx::add_port_map bus2ip_mstrd_src_dsc_n $bus
set_property physical_name bus2ip_mstrd_src_dsc_n [ipx::get_port_maps bus2ip_mstrd_src_dsc_n -of_objects $bus]
ipx::add_port_map ip2bus_mst_be $bus
set_property physical_name ip2bus_mst_be [ipx::get_port_maps ip2bus_mst_be -of_objects $bus]
ipx::add_port_map bus2ip_mstwr_dst_rdy_n $bus
set_property physical_name bus2ip_mstwr_dst_rdy_n [ipx::get_port_maps bus2ip_mstwr_dst_rdy_n -of_objects $bus]
ipx::add_port_map ip2bus_mst_reset $bus
set_property physical_name ip2bus_mst_reset [ipx::get_port_maps ip2bus_mst_reset -of_objects $bus]
ipx::add_port_map ip2bus_mstrd_dst_dsc_n $bus
set_property physical_name ip2bus_mstrd_dst_dsc_n [ipx::get_port_maps ip2bus_mstrd_dst_dsc_n -of_objects $bus]
# associate clock
ipx::associate_bus_interfaces -busif axi_master_burst_rx -clock clk [ipx::current_core]


# axi master burst interface
ipx::add_bus_interface axi_master_burst_tx [ipx::current_core]
set bus [ipx::get_bus_interfaces axi_master_burst_tx -of_objects [ipx::current_core]]
set_property abstraction_type_vlnv Xilinx:user:axi_master_burst_rtl:1.0 $bus
set_property bus_type_vlnv Xilinx:user:axi_master_burst_tx:1.0 $bus
set_property interface_mode master $bus
# mapping
ipx::add_port_map tx_bus2ip_mstrd_d $bus
set_property physical_name tx_bus2ip_mstrd_d [ipx::get_port_maps tx_bus2ip_mstrd_d -of_objects $bus]
ipx::add_port_map tx_ip2bus_mstwr_d $bus
set_property physical_name tx_ip2bus_mstwr_d [ipx::get_port_maps tx_ip2bus_mstwr_d -of_objects $bus]
ipx::add_port_map tx_ip2bus_mstwr_src_dsc_n $bus
set_property physical_name tx_ip2bus_mstwr_src_dsc_n [ipx::get_port_maps tx_ip2bus_mstwr_src_dsc_n -of_objects $bus]
ipx::add_port_map tx_bus2ip_mst_cmdack $bus
set_property physical_name tx_bus2ip_mst_cmdack [ipx::get_port_maps tx_bus2ip_mst_cmdack -of_objects $bus]
ipx::add_port_map tx_bus2ip_mstrd_eof_n $bus
set_property physical_name tx_bus2ip_mstrd_eof_n [ipx::get_port_maps tx_bus2ip_mstrd_eof_n -of_objects $bus]
ipx::add_port_map tx_bus2ip_mst_rearbitrate $bus
set_property physical_name tx_bus2ip_mst_rearbitrate [ipx::get_port_maps tx_bus2ip_mst_rearbitrate -of_objects $bus]
ipx::add_port_map tx_bus2ip_mstwr_dst_dsc_n $bus
set_property physical_name tx_bus2ip_mstwr_dst_dsc_n [ipx::get_port_maps tx_bus2ip_mstwr_dst_dsc_n -of_objects $bus]
ipx::add_port_map tx_bus2ip_mst_cmplt $bus
set_property physical_name tx_bus2ip_mst_cmplt [ipx::get_port_maps tx_bus2ip_mst_cmplt -of_objects $bus]
ipx::add_port_map tx_ip2bus_mstwr_src_rdy_n $bus
set_property physical_name tx_ip2bus_mstwr_src_rdy_n [ipx::get_port_maps tx_ip2bus_mstwr_src_rdy_n -of_objects $bus]
ipx::add_port_map tx_ip2bus_mst_length $bus
set_property physical_name tx_ip2bus_mst_length [ipx::get_port_maps tx_ip2bus_mst_length -of_objects $bus]
ipx::add_port_map tx_bus2ip_mstrd_sof_n $bus
set_property physical_name tx_bus2ip_mstrd_sof_n [ipx::get_port_maps tx_bus2ip_mstrd_sof_n -of_objects $bus]
ipx::add_port_map tx_ip2bus_mstrd_req $bus
set_property physical_name tx_ip2bus_mstrd_req [ipx::get_port_maps tx_ip2bus_mstrd_req -of_objects $bus]
ipx::add_port_map tx_bus2ip_mst_cmd_timeout $bus
set_property physical_name tx_bus2ip_mst_cmd_timeout [ipx::get_port_maps tx_bus2ip_mst_cmd_timeout -of_objects $bus]
ipx::add_port_map tx_bus2ip_mstrd_rem $bus
set_property physical_name tx_bus2ip_mstrd_rem [ipx::get_port_maps tx_bus2ip_mstrd_rem -of_objects $bus]
ipx::add_port_map tx_ip2bus_mstwr_rem $bus
set_property physical_name tx_ip2bus_mstwr_rem [ipx::get_port_maps tx_ip2bus_mstwr_rem -of_objects $bus]
ipx::add_port_map tx_ip2bus_mst_addr $bus
set_property physical_name tx_ip2bus_mst_addr [ipx::get_port_maps tx_ip2bus_mst_addr -of_objects $bus]
ipx::add_port_map tx_ip2bus_mstwr_req $bus
set_property physical_name tx_ip2bus_mstwr_req [ipx::get_port_maps tx_ip2bus_mstwr_req -of_objects $bus]
ipx::add_port_map tx_ip2bus_mstwr_sof_n $bus
set_property physical_name tx_ip2bus_mstwr_sof_n [ipx::get_port_maps tx_ip2bus_mstwr_sof_n -of_objects $bus]
ipx::add_port_map tx_bus2ip_mstrd_src_rdy_n $bus
set_property physical_name tx_bus2ip_mstrd_src_rdy_n [ipx::get_port_maps tx_bus2ip_mstrd_src_rdy_n -of_objects $bus]
ipx::add_port_map tx_ip2bus_mst_type $bus
set_property physical_name tx_ip2bus_mst_type [ipx::get_port_maps tx_ip2bus_mst_type -of_objects $bus]
ipx::add_port_map tx_ip2bus_mstrd_dst_rdy_n $bus
set_property physical_name tx_ip2bus_mstrd_dst_rdy_n [ipx::get_port_maps tx_ip2bus_mstrd_dst_rdy_n -of_objects $bus]
ipx::add_port_map tx_bus2ip_mst_error $bus
set_property physical_name tx_bus2ip_mst_error [ipx::get_port_maps tx_bus2ip_mst_error -of_objects $bus]
ipx::add_port_map tx_ip2bus_mstwr_eof_n $bus
set_property physical_name tx_ip2bus_mstwr_eof_n [ipx::get_port_maps tx_ip2bus_mstwr_eof_n -of_objects $bus]
ipx::add_port_map tx_ip2bus_mst_lock $bus
set_property physical_name tx_ip2bus_mst_lock [ipx::get_port_maps tx_ip2bus_mst_lock -of_objects $bus]
ipx::add_port_map tx_bus2ip_mstrd_src_dsc_n $bus
set_property physical_name tx_bus2ip_mstrd_src_dsc_n [ipx::get_port_maps tx_bus2ip_mstrd_src_dsc_n -of_objects $bus]
ipx::add_port_map tx_ip2bus_mst_be $bus
set_property physical_name tx_ip2bus_mst_be [ipx::get_port_maps tx_ip2bus_mst_be -of_objects $bus]
ipx::add_port_map tx_bus2ip_mstwr_dst_rdy_n $bus
set_property physical_name tx_bus2ip_mstwr_dst_rdy_n [ipx::get_port_maps tx_bus2ip_mstwr_dst_rdy_n -of_objects $bus]
ipx::add_port_map tx_ip2bus_mst_reset $bus
set_property physical_name tx_ip2bus_mst_reset [ipx::get_port_maps tx_ip2bus_mst_reset -of_objects $bus]
ipx::add_port_map tx_ip2bus_mstrd_dst_dsc_n $bus
set_property physical_name tx_ip2bus_mstrd_dst_dsc_n [ipx::get_port_maps tx_ip2bus_mstrd_dst_dsc_n -of_objects $bus]
# associate clock
ipx::associate_bus_interfaces -busif axi_master_burst_tx -clock clk [ipx::current_core]

# uft tx interface
ipx::add_bus_interface udp_tx_ctrl [ipx::current_core]
set bus [ipx::get_bus_interfaces udp_tx_ctrl -of_objects [ipx::current_core]]
set_property abstraction_type_vlnv IME:user:udp_tx_ctrl_rtl:1.0 $bus
set_property bus_type_vlnv Xilinx:user:udp_tx_ctrl:1.0 $bus
set_property interface_mode master $bus
# mapping
ipx::add_port_map udp_tx_start $bus
set_property physical_name udp_tx_start [ipx::get_port_maps udp_tx_start -of_objects $bus]
ipx::add_port_map udp_tx_result $bus
set_property physical_name udp_tx_result [ipx::get_port_maps udp_tx_result -of_objects $bus]
ipx::add_port_map udp_tx_hdr_dst_ip_addr $bus
set_property physical_name udp_tx_hdr_dst_ip_addr [ipx::get_port_maps udp_tx_hdr_dst_ip_addr -of_objects $bus]
ipx::add_port_map udp_tx_hdr_dst_port $bus
set_property physical_name udp_tx_hdr_dst_port [ipx::get_port_maps udp_tx_hdr_dst_port -of_objects $bus]
ipx::add_port_map udp_tx_hdr_src_port $bus
set_property physical_name udp_tx_hdr_src_port [ipx::get_port_maps udp_tx_hdr_src_port -of_objects $bus]
ipx::add_port_map udp_tx_hdr_data_length $bus
set_property physical_name udp_tx_hdr_data_length [ipx::get_port_maps udp_tx_hdr_data_length -of_objects $bus]
ipx::add_port_map udp_tx_hdr_checksum $bus
set_property physical_name udp_tx_hdr_checksum [ipx::get_port_maps udp_tx_hdr_checksum -of_objects $bus]
# associate clock
ipx::associate_bus_interfaces -busif udp_tx_ctrl -clock clk [ipx::current_core]

# uft rx interface
ipx::add_bus_interface udp_rx_ctrl [ipx::current_core]
set bus [ipx::get_bus_interfaces udp_rx_ctrl -of_objects [ipx::current_core]]
set_property abstraction_type_vlnv IME:user:udp_rx_ctrl_rtl:1.0 $bus
set_property bus_type_vlnv Xilinx:user:udp_rx_ctrl:1.0 $bus
set_property interface_mode slave $bus
# mapping
ipx::add_port_map udp_rx_start $bus
set_property physical_name udp_rx_start [ipx::get_port_maps udp_rx_start -of_objects $bus]
ipx::add_port_map udp_rx_hdr_is_valid $bus
set_property physical_name udp_rx_hdr_is_valid [ipx::get_port_maps udp_rx_hdr_is_valid -of_objects $bus]
ipx::add_port_map udp_rx_hdr_src_ip_addr $bus
set_property physical_name udp_rx_hdr_src_ip_addr [ipx::get_port_maps udp_rx_hdr_src_ip_addr -of_objects $bus]
ipx::add_port_map udp_rx_hdr_src_port $bus
set_property physical_name udp_rx_hdr_src_port [ipx::get_port_maps udp_rx_hdr_src_port -of_objects $bus]
ipx::add_port_map udp_rx_hdr_dst_port $bus
set_property physical_name udp_rx_hdr_dst_port [ipx::get_port_maps udp_rx_hdr_dst_port -of_objects $bus]
ipx::add_port_map udp_rx_hdr_data_length $bus
set_property physical_name udp_rx_hdr_data_length [ipx::get_port_maps udp_rx_hdr_data_length -of_objects $bus]
# associate clock
ipx::associate_bus_interfaces -busif udp_rx_ctrl -clock clk [ipx::current_core]


# AXI  bus clocks

# Fix bus associations
