#!/bin/bash

# convert image to binary data
../../../../../sw/image2file/image2file room.jpg room_in.bin

# copy to FPGA, run wallis and copy back
vivado -nolog -nojournal -mode batch -source wallis_tb.tcl

# convert back to imag
../../../../../sw/file2image/file2image room_out.bin room_out.jpg 680 558 -s
