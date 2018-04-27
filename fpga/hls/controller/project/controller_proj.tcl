############################################################
## This file is generated automatically by Vivado HLS.
## Please DO NOT edit it.
## Copyright (C) 1986-2017 Xilinx, Inc. All Rights Reserved.
############################################################
open_project -reset controller
set_top controller_top
add_files ../user/source/controller.cpp
add_files -tb ../user/testbench/controller_tb.cpp


# Solution
open_solution -reset "controller"
set_part {xc7a200tfbg676-2} -tool vivado
create_clock -period 8 -name default
#source "./controller/controller/directives.tcl"

csim_design -compiler gcc
csynth_design
cosim_design -rtl vhdl -tool xsim
export_design -flow impl -rtl vhdl -format ip_catalog -description "diip Controller" -vendor "ime" -library "diip" -version "0.1" -display_name "diip_controller"
exit
