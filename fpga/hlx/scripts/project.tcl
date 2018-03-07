# ================================================================================
# project.tcl
# 
# Creates the project, sets appropriate parameters and adds the top
# block design
# 
# by Noah Huetter <noahhuetter@gmail.com>
# based on Pavel Demin's 'red-pitaya-notes-master' git repo
# ================================================================================
# Usage
# vivado -nolog -nojournal -mode batch -source \
#   scripts/project.tcl -tclargs project_name part_name build_location ip_location
# ================================================================================

# Settings
set project_name [lindex $argv 0]
set part_name [lindex $argv 1]
set build_location [lindex $argv 2]
set ip_location [lindex $argv 3]

# Cleanup
file delete -force $build_location/$project_name.cache $build_location/$project_name.hw $build_location/$project_name.srcs $build_location/$project_name.runs $build_location/$project_name.xpr

# Create project
create_project -part $part_name $project_name $build_location -force

# Link to IPs
set_property IP_REPO_PATHS "$ip_location/ ../hls/sobel/project/sobel/sobel/impl/ip" [current_project]

# Project settings
set obj [current_project]
set_property -name "board_part" -value "xilinx.com:ac701:part0:1.3" -objects $obj
set_property -name "target_language" -value "VHDL" -objects $obj

# Block design target location
set bd_path $build_location/$project_name.srcs/sources_1/bd/system
create_bd_design system

# Create block design ports
source config/bd_ports.tcl

##
## @brief      { function_description }
##
## @param      cell_vlnv   The cell vlnv
## @param      cell_name   The cell name
## @param      cell_props  The cell properties
## @param      cell_ports  The cell ports
##
## @return     { description_of_the_return_value }
##
proc cell {cell_vlnv cell_name {cell_props {}} {cell_ports {}}} {
  set cell [create_bd_cell -type ip -vlnv $cell_vlnv $cell_name]
  set prop_list {}
  foreach {prop_name prop_value} [uplevel 1 [list subst $cell_props]] {
    lappend prop_list CONFIG.$prop_name $prop_value
  }
  if {[llength $prop_list] > 1} {
    set_property -dict $prop_list $cell
  }
  foreach {local_name remote_name} [uplevel 1 [list subst $cell_ports]] {
    set local_port [get_bd_pins $cell_name/$local_name]
    set remote_port [get_bd_pins $remote_name]
    if {[llength $local_port] == 1 && [llength $remote_port] == 1} {
      connect_bd_net $local_port $remote_port
      continue
    }
    set local_port [get_bd_intf_pins $cell_name/$local_name]
    set remote_port [get_bd_intf_pins $remote_name]
    if {[llength $local_port] == 1 && [llength $remote_port] == 1} {
      connect_bd_intf_net $local_port $remote_port
      continue
    }
    error "** ERROR: can't connect $cell_name/$local_name and $remote_name"
  }
}

##
## @brief      { function_description }
##
## @param      module_name   The module name
## @param      module_body   The module body
## @param      module_ports  The module ports
##
## @return     { description_of_the_return_value }
##
# proc module {module_name module_body {module_ports {}}} {
#   set bd [current_bd_instance .]
#   current_bd_instance [create_bd_cell -type hier $module_name]
#   eval $module_body
#   current_bd_instance $bd
#   foreach {local_name remote_name} [uplevel 1 [list subst $module_ports]] {
#     set local_port [get_bd_pins $module_name/$local_name]
#     set remote_port [get_bd_pins $remote_name]
#     if {[llength $local_port] == 1 && [llength $remote_port] == 1} {
#       connect_bd_net $local_port $remote_port
#       continue
#     }
#     set local_port [get_bd_intf_pins $module_name/$local_name]
#     set remote_port [get_bd_intf_pins $remote_name]
#     if {[llength $local_port] == 1 && [llength $remote_port] == 1} {
#       connect_bd_intf_net $local_port $remote_port
#       continue
#     }
#     error "** ERROR: can't connect $module_name/$local_name and $remote_name"
#   }
# }

# Create block design
source projects/$project_name/block_design.tcl
save_bd_design

rename cell {}
# rename module {}

# Enable synthesis for block design
set_property synth_checkpoint_mode None [get_files $bd_path/system.bd]

# Generate output products
generate_target all [get_files $bd_path/system.bd]
make_wrapper -files [get_files $bd_path/system.bd] -top

# add system wrapper source
add_files -norecurse $bd_path/hdl/system_wrapper.vhd

# Add user vhd files
set files [glob -nocomplain projects/$project_name/hdl/*.vhd]
if {[llength $files] > 0} {
  add_files -norecurse $files
}
# Add user constraints
set files [glob -nocomplain config/*.xdc projects/$project_name/constraints/*.xdc]
if {[llength $files] > 0} {
  add_files -norecurse -fileset constrs_1 $files
}

# set_property STRATEGY Flow_PerfOptimized_high [get_runs synth_1]
# set_property STRATEGY Performance_NetDelay_high [get_runs impl_1]

close_project
