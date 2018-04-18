############################################################
## This file is generated automatically by Vivado HLS.
## Please DO NOT edit it.
## Copyright (C) 1986-2017 Xilinx, Inc. All Rights Reserved.
############################################################
open_project -reset clahe_proj
set_top clahe
add_files ../user/source/clahe.cpp
add_files -tb ../user/input_files/landscape.jpg
add_files -tb ../user/testbench/tb_clahe.cpp


# Solution
open_solution -reset "clahe_sol"
set_part {xc7a200tfbg676-2} -tool vivado
create_clock -period 8 -name default
#source "./sobel/sobel/directives.tcl"

csim_design -compiler gcc
#csynth_design
#cosim_design -rtl vhdl -tool xsim
#export_design -flow impl -rtl vhdl -format ip_catalog -description "CLAHE" -vendor "ime" -library "image_processing" -version "0.0.1" -display_name "clahe"
exit
