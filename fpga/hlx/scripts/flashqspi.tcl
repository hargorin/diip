# ================================================================================
# flashqspi.tcl
# 
# Writes Generates memory config file and stores it in the FPGA config flash part
# 
# by Noah Huetter <noahhuetter@gmail.com>
# ================================================================================
# Usage
# vivado -nolog -nojournal -mode batch -source \
#   scripts/flashqspi.tcl -tclargs project_name project_location bit_location
# ================================================================================
set project_name [lindex $argv 0]
set project_location [lindex $argv 1]
set bit_location [lindex $argv 2]

open_project $project_location/$project_name.xpr

write_cfgmem -force -format mcs -size 32 -interface SPIx1 -loadbit [concat "up 0x00000000 " $bit_location/$project_name.bit] -file $bit_location/$project_name.mcs

open_hw
connect_hw_server
open_hw_target
create_hw_cfgmem -hw_device [lindex [get_hw_devices xc7a200t_0] 0] [lindex [get_cfgmem_parts {mt25ql256-spi-x1_x2_x4}] 0]

set_property PROGRAM.BLANK_CHECK  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0]]
set_property PROGRAM.ERASE  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0]]
set_property PROGRAM.CFG_PROGRAM  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0]]
set_property PROGRAM.VERIFY  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0]]
set_property PROGRAM.CHECKSUM  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0]]
refresh_hw_device [lindex [get_hw_devices xc7a200t_0] 0]
set_property PROGRAM.ADDRESS_RANGE  {use_file} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0]]
set_property PROGRAM.FILES [list $bit_location/$project_name.mcs] [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0]]
set_property PROGRAM.PRM_FILE {} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0]]
set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0]]
set_property PROGRAM.BLANK_CHECK  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0]]
set_property PROGRAM.ERASE  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0]]
set_property PROGRAM.CFG_PROGRAM  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0]]
set_property PROGRAM.VERIFY  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0]]
set_property PROGRAM.CHECKSUM  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0]]
startgroup 
if {![string equal [get_property PROGRAM.HW_CFGMEM_TYPE  [lindex [get_hw_devices xc7a200t_0] 0]] [get_property MEM_TYPE [get_property CFGMEM_PART [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0]]]]] }  { create_hw_bitstream -hw_device [lindex [get_hw_devices xc7a200t_0] 0] [get_property PROGRAM.HW_CFGMEM_BITFILE [ lindex [get_hw_devices xc7a200t_0] 0]]; program_hw_devices [lindex [get_hw_devices xc7a200t_0] 0]; }; 
program_hw_cfgmem -hw_cfgmem [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0]]
endgroup
