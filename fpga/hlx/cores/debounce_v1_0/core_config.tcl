
# Display name of the core
set display_name {Debouncer}

# set core
set core [ipx::current_core]

# set core properties
set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $display_name $core

# Set Core Parameters
# proc core_parameter {name display_name description} defined in core.tcl
core_parameter C_COUNTER_SIZE {Debounce counter size} {DebounceTime = (2^C_COUNTER_SIZE + 2)/f}

