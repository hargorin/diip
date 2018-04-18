############################################################
## This file is generated automatically by Vivado HLS.
## Please DO NOT edit it.
## Copyright (C) 1986-2017 Xilinx, Inc. All Rights Reserved.
############################################################
open_project -reset wallis_proj
set_top wallis
add_files ../user/source/wallis.cpp
add_files -tb ../user/input_files/landscape.jpg
add_files -tb ../user/testbench/tb_wallis.cpp


# Solution
open_solution -reset "wallis_sol"
set_part {xc7a200tfbg676-2} -tool vivado
create_clock -period 8 -name default
#source "./sobel/sobel/directives.tcl"

csim_design -compiler gcc
#csynth_design
#cosim_design -rtl vhdl -tool xsim
#export_design -flow impl -rtl vhdl -format ip_catalog -description "WALLIS" -vendor "ime" -library "image_processing" -version "0.0.1" -display_name "wallis"
exit
