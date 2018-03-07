
# Display name of the core
set display_name {AXI Master to ipif}

# set core
set core [ipx::current_core]

# set core properties
set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $display_name $core

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
