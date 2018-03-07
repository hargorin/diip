
# Display name of the core
set display_name {UFT Stack}

# Set top module
set_property top uft_top [current_fileset]

# set core
set core [ipx::current_core]

# set core properties
set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $display_name $core

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

# AXI  bus clocks

# Fix bus associations
