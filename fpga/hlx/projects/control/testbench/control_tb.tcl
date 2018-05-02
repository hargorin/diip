# @Author: Noah
# @Date:   2018-04-26 10:24:03
# @Last Modified by:   Noah
# @Last Modified time: 2018-05-02 11:53:12

#############################################
# connect_xc7a200t
proc connect {} {
  connect_hw_server
  open_hw_target

  set_property PROGRAM.FILE {build/projects/control.runs/impl_1/system_wrapper.bit} [get_hw_devices xc7a200t_0]
  set_property PROBES.FILE {build/projects/control.runs/impl_1/system_wrapper.ltx} [get_hw_devices xc7a200t_0]
  set_property FULL_PROBES.FILE {build/projects/control.runs/impl_1/system_wrapper.ltx} [get_hw_devices xc7a200t_0]
  current_hw_device [get_hw_devices xc7a200t_0]
  refresh_hw_device [lindex [get_hw_devices xc7a200t_0] 0]
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
# open_hw
# connect_xc7a200t


# close_hw
