############################################################
## This file is generated automatically by Vivado HLS.
## Please DO NOT edit it.
## Copyright (C) 1986-2017 Xilinx, Inc. All Rights Reserved.
############################################################
open_project -reset sobel
set_top sobel_abs
add_files ../user/source/sobel.cpp
add_files -tb ../user/test_images/Lena128.bmp
add_files -tb ../user/test_images/tiff/airport.tiff
add_files -tb ../user/test_images/tiff/bridge.tiff
add_files -tb ../user/test_images/tiff/street1024.tif
add_files -tb ../user/test_images/tiff/street512.tif
add_files -tb ../user/test_images/test_1080p.bmp
add_files -tb ../user/testbench/test_sobel.cpp


# Solution
open_solution -reset "sobel"
set_part {xc7a200tfbg676-2} -tool vivado
create_clock -period 10 -name default
#source "./sobel/sobel/directives.tcl"

csim_design -compiler gcc
csynth_design
cosim_design -rtl vhdl -tool xsim
export_design -flow impl -rtl vhdl -format ip_catalog -description "Sobel-Filter" -vendor "ime" -library "image_processing" -version "1.1.12" -display_name "sobel_filter"
exit
