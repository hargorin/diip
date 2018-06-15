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

#############################################
# Testbench for commit 6777dc8
proc tb1 {} {
  # # Write data to image input base
  writeto room_in.bin 0

  # Write image width
  create_hw_axi_txn wrimgwidth [get_hw_axis] -force -address 0xc0000020 -type write -data 00000100
  run_hw_axi wrimgwidth

  # Push SW5 to run calculation
  puts "Push SW5 to start processing"
  puts "Press enter when done"
  anykey

  # Dump output data
  # dump room_out.bin 379440 355080
  dump room_out.bin 10000 55696

  # Check data
  puts "Check output data in out.bin"
}

#############################################
# Testbench for commit xxxxxxx
proc tb2 {} {
  # Write image width 128 to uft source register
  create_hw_axi_txn wrimgwidth [get_hw_axis] -force -address 0xc0000020 -type write -data 00000080
  run_hw_axi wrimgwidth
  # Write UFT status to tx_ready
  create_hw_axi_txn wrimgwidth [get_hw_axis] -force -address 0xc0000000 -type write -data 00000001
  run_hw_axi wrimgwidth


  for {set i 0} {$i < 108} {incr i} {
      # Write data to image input base
      puts [format "workdir/row_%03d.bin" $i]
      writeto [format "workdir/row_%03d.bin" $i] 0
      # puts "Push SW5 to start processing"
      # anykey
      # launch controller
      create_hw_axi_txn startctrl [get_hw_axis] -force -address 0x40000000 -type write -data ffffffff
      run_hw_axi startctrl
      create_hw_axi_txn startctrl [get_hw_axis] -force -address 0x40000000 -type write -data 00000000
      run_hw_axi startctrl
      dump [format "workdir/in_%03d.bin" $i] a80 108
  }

  # Check data
  puts "Check output data in workdir/in_*.bin"
}

# --------
#   main
# --------
  source memdump.tcl
  open_hw
  connect

  # tb1
  tb2

  close_hw