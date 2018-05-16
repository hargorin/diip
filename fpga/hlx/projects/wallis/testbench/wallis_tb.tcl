# @Author: Noah
# @Date:   2018-04-26 10:24:03
# @Last Modified by:   Noah
# @Last Modified time: 2018-05-02 11:53:12

#############################################
# connect_xc7a200t
proc connect {} {
  connect_hw_server
  open_hw_target

  set_property PROGRAM.FILE {../../../build/projects/wallis.runs/impl_1/system_wrapper.bit} [get_hw_devices xc7a200t_0]
  set_property PROBES.FILE {../../../build/projects/wallis.runs/impl_1/system_wrapper.ltx} [get_hw_devices xc7a200t_0]
  set_property FULL_PROBES.FILE {../../../build/projects/wallis.runs/impl_1/system_wrapper.ltx} [get_hw_devices xc7a200t_0]
  current_hw_device [get_hw_devices xc7a200t_0]
  refresh_hw_device [lindex [get_hw_devices xc7a200t_0] 0]
}
# connect_xc7a200t
proc disconnect {} {
  disconnect_hw_server
}

proc anykey {{msg "Hit any key: "}} {
    set stty_settings [exec stty -g]
    exec stty raw -echo
    puts -nonewline $msg
    flush stdout
    read stdin 1
    exec stty $stty_settings
    puts ""
}

#############################################
# configure device
# Only after connect
proc flash {} {
    program_hw_devices [get_hw_devices xc7a200t_0]
}

# --------
#   main
# --------
source memdump.tcl
open_hw
connect

# Write data to image input base
writeto room_in.bin 0

# Push SW5 to run calculation
puts "Push SW5 to start processing"
puts "Press enter when done"
anykey

# Dump output data
dump room_out.bin 379440 355080

# Check data
puts "Check output data in out.bin"

# close_hw
