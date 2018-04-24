############################################################
## This file is generated automatically by Vivado HLS.
## Please DO NOT edit it.
## Copyright (C) 1986-2017 Xilinx, Inc. All Rights Reserved.
############################################################

############################################################
## Project
############################################################
open_project -reset wallis_proj
set_top wallis
add_files ../user/source/wallis.cpp
add_files -tb ../user/input_files/landscape.jpg
add_files -tb ../user/testbench/tb_wallis.cpp


############################################################
## Solutions
############################################################
# Solution 0
open_solution -reset "sol0_wallis"
set_part {xc7a200tfbg676-2} -tool vivado
create_clock -period 8 -name default
source "../user/directives/directives_sol0.tcl"

# Solution 1
open_solution -reset "sol1_pixel_opt"
set_part {xc7a200tfbg676-2} -tool vivado
create_clock -period 8 -name default
source "../user/directives/directives_sol1.tcl"

# Solution 2
open_solution -reset "sol2_pixel_opt"
set_part {xc7a200tfbg676-2} -tool vivado
create_clock -period 8 -name default
source "../user/directives/directives_sol2.tcl"


############################################################
## Verification
############################################################
#csim_design -compiler gcc
csynth_design
#cosim_design -rtl vhdl -tool xsim
#export_design -flow impl -rtl vhdl -format ip_catalog -description "WALLIS" -vendor "ime" -library "image_processing" -version "0.0.1" -display_name "wallis"
exit
