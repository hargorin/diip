# ================================================================================
# bitstream.tcl
# 
# Writes the bitstream
# 
# by Noah Huetter <noahhuetter@gmail.com>
# based on Pavel Demin's 'red-pitaya-notes-master' git repo
# ================================================================================
# Usage
# vivado -nolog -nojournal -mode batch -source \
#   scripts/bitstream.tcl -tclargs project_name project_location bit_location
# ================================================================================
set project_name [lindex $argv 0]
set project_location [lindex $argv 1]
set bit_location [lindex $argv 2]

open_project $project_location/$project_name.xpr

puts [get_property PROGRESS [get_runs impl_1]]

if {[get_property PROGRESS [get_runs impl_1]] == "100%"} {
    open_run [get_runs impl_1]

    set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

    write_bitstream -force -file $bit_location/$project_name.bit
    write_debug_probes -force -file $bit_location/$project_name.ltx

    close_project
} else {
    puts "ERROR: Implementation out of date"
}
