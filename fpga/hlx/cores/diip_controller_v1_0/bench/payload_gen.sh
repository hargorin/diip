#!/bin/bash

# IMAGE="mountain.tif"
IMAGE="room128x128.jpg"
WIN_SIZE=21

# Get information
WIDTH=$(identify  -format '%w' $IMAGE)
HEIGHT=$(identify  -format '%h' $IMAGE)

# Binraies
IMAGE2FILE="../../../../../sw/image2file/image2file"
FILE2IMAGE="../../../../../sw/file2image/file2image"

# Convert image to binary
$IMAGE2FILE $IMAGE inputimg.bin
# Convert binary to hex
xxd -p inputimg.bin | tr -d '\n' | fold -w2 > $IMAGE.txt

# Test if correct xxd
# # Convert hex to binary 
# cat $IMAGE.txt | tr -d '\n' | xxd -r -p > outputimg.bin
# # Convert binary to image
# $FILE2IMAGE outputimg.bin outputimg.jpg `expr $HEIGHT` `expr $WIDTH` -s


echo "Run testbench now. Sleeping for 10 seconds..."
sleep 1

# Convert hex to binary 
cat ../../../build/ghdl/axi_stream_res_*.log | tr -d '\n' | xxd -r -p > outputimg.bin
# Convert binary to image
$FILE2IMAGE outputimg.bin outputimg.jpg `expr $HEIGHT - $WIN_SIZE + 1` `expr $WIDTH - $WIN_SIZE + 1` -s
