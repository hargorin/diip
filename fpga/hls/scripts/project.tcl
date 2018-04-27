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

# Create project
open_project -reset $project_name

# Get project settings
source ../projects/$project_name/project.tcl

# Set top function
set_top $proj_top_function

# Add source files
add_files [glob -directory ../projects/$project_name/src/ *] -cflags "-I../projects/$project_name/inc/"
add_files [glob -directory ../projects/$project_name/directives/ *] -cflags "-I../projects/$project_name/inc/"

# Add testbench files
add_files -tb [glob -directory ../projects/$project_name/bench/ *]

# Create solution
open_solution "sol_0"
set_part $proj_part_name -tool vivado
create_clock -period $proj_clk_period -name default
exit