#!/bin/bash

# convert image to binary data
image2file room128x128.jpg room_in.bin

# split it into files
mkdir -p filesplit/out
filesplit/filesplit room_in.bin 128 filesplit/out/

# copy to FPGA, run wallis and copy back
vivado -nolog -nojournal -mode batch -source wallis_tb.tcl

# merge files
filesplit/filemerge room_out.bin filesplit/out/in_*.bin

# convert back to imag
file2image room_out.bin room_out.jpg 108 108 -s
