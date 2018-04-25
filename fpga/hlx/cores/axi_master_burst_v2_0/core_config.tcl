
# Display name of the core
set display_name {AXI Master to ipif}

# set core
set core [ipx::current_core]

# set core properties
set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $display_name $core
set_property VERSION 2.1 $core

# Set Core Parameters
# proc core_parameter {name display_name description} defined in core.tcl
core_parameter C_M_AXI_DATA_WIDTH {AXI DATA WIDTH} {Width of the AXI data bus.}
core_parameter C_M_AXI_ADDR_WIDTH {AXI ADDR WIDTH} {Width of the AXI address bus.}
core_parameter C_MAX_BURST_LEN {MAX BURST LEN} {Specifies the max number of databeats to use for each AXI MMap transfer by the AXI Master Burst}
core_parameter C_ADDR_PIPE_DEPTH {ADDR PIPE DEPTH} {Specifies the address pipeline depth for the AXI Master Burst}
core_parameter C_NATIVE_DATA_WIDTH {NATIVE DATA WIDTH} {Set this equal to desired data bus width needed by IPIC LocalLink Data Channels.}
core_parameter C_LENGTH_WIDTH {LENGTH WIDTH} {Set this to the desired bit width for the ip2bus_mst_length input port required to specify the maximimum transfer byte count needed for any one command by the User logic.}

# C_FAMILY is somehow not automatically recognized
ipx::add_user_parameter C_FAMILY [ipx::current_core]
ipgui::add_param -name {C_FAMILY} -component [ipx::current_core] -display_name {FPGA FAMILY} -show_label {true} -show_range {true} -widget {}
set_property value artix7 [ipx::get_hdl_parameters C_FAMILY -of_objects [ipx::current_core]]
set_property value artix7 [ipx::get_user_parameters C_FAMILY -of_objects [ipx::current_core]]
# ipx::add_user_parameter C_FAMILY [ipx::current_core]
# set_property value_resolve_type user [ipx::get_user_parameters C_FAMILY -of_objects [ipx::current_core]]
# ipgui::add_param -name {C_FAMILY} -component [ipx::current_core]
# set_property display_name {C Family} [ipgui::get_guiparamspec -name "C_FAMILY" -component [ipx::current_core] ]
# set_property widget {textEdit} [ipgui::get_guiparamspec -name "C_FAMILY" -component [ipx::current_core] ]
core_parameter C_FAMILY {FPGA FAMILY} {Target FPGA Device Family}

# Define busses
set bus [ipx::get_bus_interfaces -of_objects $core m_axi]
set_property NAME M_AXI $bus
set_property INTERFACE_MODE master $bus

set bus [ipx::get_bus_interfaces m_axi_aclk]
set parameter [ipx::get_bus_parameters -of_objects $bus ASSOCIATED_BUSIF]
set_property VALUE M_AXI $parameter

# axi master burst interface
ipx::add_bus_interface axi_master_burst [ipx::current_core]
set bus [ipx::get_bus_interfaces axi_master_burst -of_objects [ipx::current_core]]
set_property abstraction_type_vlnv Xilinx:user:axi_master_burst_rtl:1.0 $bus
set_property bus_type_vlnv Xilinx:user:axi_master_burst:1.0 $bus
set_property interface_mode slave $bus
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
ipx::associate_bus_interfaces -busif axi_master_burst -clock m_axi_aclk [ipx::current_core]
