# ================================================================================
# csim.tcl
# 
# Runs C simulation on project
# 
# by Noah Huetter <noahhuetter@gmail.com>
# ================================================================================
# Usage
# vivado_hls -f scripts/csim.tcl -tclargs \
#    project_name
# ================================================================================

# Settings
set project_name [lindex $argv 2]

# Get project settings
source ../projects/$project_name/project.tcl

# Create project
open_project $project_name
open_solution $proj_top_solution
set_part $proj_part_name -tool vivado
create_clock -period $proj_clk_period -name default

csim_design -compiler gcc

exit