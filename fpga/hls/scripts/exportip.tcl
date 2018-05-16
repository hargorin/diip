# ================================================================================
# exportip.tcl
# 
# Exports design as IP
# 
# by Noah Huetter <noahhuetter@gmail.com>
# ================================================================================
# Usage
# vivado_hls -f scripts/exportip.tcl -tclargs \
#    project_name
# ================================================================================

# Settings
set project_name [lindex $argv 2]

# Get project settings
source ../projects/$project_name/project.tcl

# Create project
open_project $project_name
open_solution "sol_0"
set_part $proj_part_name -tool vivado
create_clock -period $proj_clk_period -name default

export_design -rtl vhdl -format ip_catalog -description $proj_desc -vendor $proj_vendor -library $proj_library -version $proj_version -display_name $proj_display_name

exit