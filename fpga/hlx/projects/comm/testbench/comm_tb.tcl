# @Author: Noah
# @Date:   2018-04-26 10:24:03
# @Last Modified by:   Noah
# @Last Modified time: 2018-05-02 11:53:12

#############################################
# connect_xc7a200t
proc connect {} {
  connect_hw_server
  open_hw_target

  set_property PROGRAM.FILE {../../../build/projects/comm.runs/impl_1/system_wrapper.bit} [get_hw_devices xc7a200t_0]
  set_property PROBES.FILE {../../../build/projects/comm.runs/impl_1/system_wrapper.ltx} [get_hw_devices xc7a200t_0]
  set_property FULL_PROBES.FILE {../../../build/projects/comm.runs/impl_1/system_wrapper.ltx} [get_hw_devices xc7a200t_0]
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

##
## @brief      Sets the UFT regsiters to the correct values
##
## @return     nothing
##
proc setUFTregs {} {
  
  set hw_axi hw_axi_2

  # Control: 0
  create_hw_axi_txn wr_t $hw_axi -force -address 0000_0004 -data 0000_0000 -type write
  run_hw_axi wr_t
  # UFT_REG_RX_BASE: 0
  create_hw_axi_txn wr_t $hw_axi -force -address 0000_0008 -data 0000_0000 -type write
  run_hw_axi wr_t
  # UFT_REG_TX_BASE: 0
  create_hw_axi_txn wr_t $hw_axi -force -address 0000_000c -data 0000_0000 -type write
  run_hw_axi wr_t
  # UFT_REG_TX_SIZE: 0x400
  create_hw_axi_txn wr_t $hw_axi -force -address 0000_0014 -data 0000_0400 -type write
  run_hw_axi wr_t
}


##
## @brief      Starts a UFT send procedure
##
## @return     nothing
##
proc UFTsend {} {
  set hw_axi hw_axi_2
  # UFT_REG_TX_SIZE: 0x400
  create_hw_axi_txn wr_t $hw_axi -force -address 0000_0014 -data 0000_0400 -type write
  run_hw_axi wr_t
  # Control: tx_start
  create_hw_axi_txn wr_t $hw_axi -force -address 0000_0004 -data 0000_0001 -type write
  run_hw_axi wr_t
}

##
## @brief      Reads the UFT user registers 0 through 7
##
## @return     nothing
##
proc readUserRegister {} {
  set hw_axi hw_axi_2
  puts "UFT user register in ascending order beginning with register 0:"
  # UFT_REG_USER_0
  create_hw_axi_txn rd_t $hw_axi -force -address 0000_0020 -type read -len 1
  run_hw_axi rd_t
  # UFT_REG_USER_1
  create_hw_axi_txn rd_t $hw_axi -force -address 0000_0024 -type read -len 1
  run_hw_axi rd_t
  # UFT_REG_USER_2
  create_hw_axi_txn rd_t $hw_axi -force -address 0000_0028 -type read -len 1
  run_hw_axi rd_t
  # UFT_REG_USER_3
  create_hw_axi_txn rd_t $hw_axi -force -address 0000_002c -type read -len 1
  run_hw_axi rd_t
  # UFT_REG_USER_4
  create_hw_axi_txn rd_t $hw_axi -force -address 0000_0030 -type read -len 1
  run_hw_axi rd_t
  # UFT_REG_USER_5
  create_hw_axi_txn rd_t $hw_axi -force -address 0000_0034 -type read -len 1
  run_hw_axi rd_t
  # UFT_REG_USER_6
  create_hw_axi_txn rd_t $hw_axi -force -address 0000_0038 -type read -len 1
  run_hw_axi rd_t
  # UFT_REG_USER_7
  create_hw_axi_txn rd_t $hw_axi -force -address 0000_003c -type read -len 1
  run_hw_axi rd_t
  puts "End UFT user register"
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
setUFTregs

# Send data to FPGA
exec ./workdir/sender 192.168.5.9 payload.txt

# Start sending data back to PC
UFTsend

# Dump user registers for validation
readUserRegister

# Done
disconnect
close_hw
