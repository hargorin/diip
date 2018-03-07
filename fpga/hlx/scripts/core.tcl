# ==================================================================================================
# core.tcl
#
# Creates IP core
#
# by Noah Huetter <noahhuetter@gmail.com>
# based on Anton Potocnik
# based on Pavel Demin's 'red-pitaya-notes-master' git repo
# ==================================================================================================
# Usage: 
# vivado -nolog -nojournal -mode batch -source \
#   scripts/core.tcl -tclargs core_name part_name build_location
# ==================================================================================================

# Settings
# Default IP settings
set ip_library {diip}
set ip_supported_families {artix7 Production}
set ip_vendor {ime}
set ip_vendor_disp_name {IME}
set ip_company_url {https://www.fhnw.ch/de/die-fhnw/hochschulen/ht/institute/institut-fuer-mikroelektronik}

# get inputs
set core_name [lindex $argv 0]
set part_name [lindex $argv 1]
set build_location [lindex $argv 2]

# Extract core name and version from fully qualified core name
set elements [split $core_name _]
set project_name [join [lrange $elements 0 end-2] _]
set version [string trimleft [join [lrange $elements end-1 end] .] v]

# Delete all existing files and directories with the same core name and version
file delete -force $build_location/$core_name $build_location/$project_name.cache $build_location/$project_name.hw $build_location/$project_name.xpr

# Create a project which is used to build the core
create_project -part $part_name $project_name $build_location -force

# Add all files the core needs
set vhdl_files [glob -nocomplain cores/$core_name/hdl/*.vhd]
set bench_files [glob -nocomplain cores/$core_name/bench/*.vhd]
set constr_files [glob -nocomplain cores/$core_name/*.xdc]
foreach file $vhdl_files {
    if {[file exists $file]} {
        add_files -fileset sources_1 -norecurse $file
    }
}
foreach file $bench_files {
    if {[file exists $file]} {
        add_files -fileset sim_1 -norecurse $file
    }
}
foreach file $constr_files {
    if {[file exists $file]} {
        add_files -fileset constrs_1 -norecurse $file
    }
}

# Package a new IP
ipx::package_project -import_files -root_dir $build_location/$core_name

# Remember core to set properties
set core [ipx::current_core]

# Set core properties
set_property VERSION $version $core
set_property NAME $project_name $core
set_property LIBRARY $ip_library $core
set_property SUPPORTED_FAMILIES $ip_supported_families $core
set_property VENDOR $ip_vendor $core
set_property VENDOR_DISPLAY_NAME $ip_vendor_disp_name $core
set_property COMPANY_URL $ip_company_url $core

# Sets core properties 
# will be called from inside the specific core_config.tcl comming with each core
proc core_parameter {name display_name description} {
  set core [ipx::current_core]

  set parameter [ipx::get_user_parameters $name -of_objects $core]
  set_property DISPLAY_NAME $display_name $parameter
  set_property DESCRIPTION $description $parameter

  set parameter [ipgui::get_guiparamspec -name $name -component $core]
  set_property DISPLAY_NAME $display_name $parameter
  set_property TOOLTIP $description $parameter
}

# Set core specific properties
source cores/$core_name/core_config.tcl

# Remove command to set core properties
rename core_parameter {}

# Store all files and close project
ipx::create_xgui_files $core
ipx::update_checksums $core
ipx::save_core $core
close_project

