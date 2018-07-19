#!/bin/bash

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
xxd -p inputimg.bin | tr -d '\n' | fold -w2 > inputimg.txt

echo "Run testbench now. Sleeping for 10 seconds..."
sleep 10

# Convert hex to binary 
cat axi_stream_res_*.txt | tr -d '\n' | xxd -r -p > outputimg.bin
# Convert binary to image
$FILE2IMAGE outputimg.bin outputimg.jpg `expr $HEIGHT - $WIN_SIZE + 1` `expr $WIDTH - $WIN_SIZE + 1` -s
