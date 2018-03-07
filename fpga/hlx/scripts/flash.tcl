# ================================================================================
# flash.tcl
# 
# Configures the FPGA with the provided bitstream
# 
# by Noah Huetter <noahhuetter@gmail.com>
# ================================================================================
# Usage
# vivado -nolog -nojournal -mode batch -source \
#   scripts/flash.tcl -tclargs project_name project_location bit_location
# ================================================================================
# @Author: Noah Huetter
# @Date:   2017-11-24 15:21:33
# @Last Modified by:   Noah Huetter
# @Last Modified time: 2017-12-06 08:56:46

set project_name [lindex $argv 0]
set project_location [lindex $argv 1]
set bit_location [lindex $argv 2]

open_project $project_location/$project_name.xpr

# open hw
open_hw
connect_hw_server
open_hw_target

# Add debug probes file if exists
if {[file exists $bit_location/$project_name.ltx]} {
    set_property PROBES.FILE $bit_location/$project_name.ltx [get_hw_devices xc7a200t_0]
    set_property FULL_PROBES.FILE $bit_location/$project_name.ltx [get_hw_devices xc7a200t_0]
}

# Add bit file
set_property PROGRAM.FILE $bit_location/$project_name.bit [get_hw_devices xc7a200t_0]

# program hw
program_hw_devices [get_hw_devices xc7a200t_0]
refresh_hw_device [lindex [get_hw_devices xc7a200t_0] 0]

close_project
