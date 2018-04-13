# ================================================================================
# synth.tcl
# 
# Synthesizes the design
# 
# by Noah Huetter <noahhuetter@gmail.com>
# ================================================================================
# Usage
# vivado -nolog -nojournal -mode batch -source \
#   scripts/synth.tcl -tclargs project_name project_location
# ================================================================================
set project_name [lindex $argv 0]
set project_location [lindex $argv 1]

open_project $project_location/$project_name.xpr

puts [get_property PROGRESS [get_runs synth_1]]

# If synth is out of date, run synth
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    reset_run synth_1
    launch_runs -jobs 4 synth_1
    wait_on_run synth_1
}

close_project