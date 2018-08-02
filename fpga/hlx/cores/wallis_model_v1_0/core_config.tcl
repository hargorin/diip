
# Display name of the core
set display_name {Wallis model}

# Set top module
set_property top walli_model [current_fileset]

# set core
set core [ipx::current_core]

# set core properties
set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $display_name $core
set_property VERSION 1.0 $core
