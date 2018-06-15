#!/bin/bash

# Workdir
mkdir -p workdir

# convert image to binary data
./image2file images/room128x128.jpg workdir/room_in.bin

# split it into files
filesplit/filesplit workdir/room_in.bin 128 workdir/

# copy to FPGA, run wallis and copy back
vivado -nolog -nojournal -mode batch -source wallis_tb.tcl

# merge files
filesplit/filemerge workdir/room_out.bin workdir/in_*.bin

# convert back to imag
HASH=$(git rev-parse --short HEAD)
./file2image workdir/room_out.bin workdir/room_fpga_$HASH.jpg 108 108

# diff with sw
compare -verbose -metric MSE workdir/room_fpga_$HASH.jpg images/wallis_hw_room128x128.jpg diff.jpg
