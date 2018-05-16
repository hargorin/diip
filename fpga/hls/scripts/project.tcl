# ================================================================================
# project.tcl
# 
# Creates the hls project, sets appropriate parameters and adds the sources
# 
# by Noah Huetter <noahhuetter@gmail.com>
# ================================================================================
# Usage
# vivado_hls -f scripts/project.tcl -tclargs \
#    project_name part_name build_location
# ================================================================================

# Settings
set project_name [lindex $argv 2]
set part_name [lindex $argv 3]
set build_location [lindex $argv 4]

# Procedure to create solution
proc create_solution {name project_name directive_file_name} {
	open_solution -reset $name
	set_part {xc7a200tfbg676-2} -tool vivado
	create_clock -period 8 -name default
	source "../projects/$project_name/directives/$directive_file_name"
}

# Create project
open_project -reset $project_name

# Get project settings
source ../projects/$project_name/project.tcl

# Set top function
set_top $proj_top_function

# Add source files
add_files [glob -directory ../projects/$project_name/src/ *] -cflags "-I../projects/$project_name/inc/"

# Add testbench files
add_files -tb [glob -directory ../projects/$project_name/bench/ *]

# Create solution
# open_solution "sol_0"
# set_part $proj_part_name -tool vivado
# create_clock -period $proj_clk_period -name default
if {[file exists "../projects/$project_name/directives/directives.tcl" ]} {
	create_solution "default_solution" $project_name "directives.tcl"
}
exit