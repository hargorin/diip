#!/bin/bash

# convert image to binary data
image2file room256x256.jpg room_in.bin

# copy to FPGA, run wallis and copy back
vivado -nolog -nojournal -mode batch -source wallis_tb.tcl

# convert back to imag
file2image room_out.bin room_out.jpg 236 236 -s
