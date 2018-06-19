#!/bin/bash

# Input arguments
IP="192.168.5.9"
IMAGE="images/room128x128.jpg"
WIN_SIZE=21

# Get information
WIDTH=$(identify  -format '%w' $IMAGE)
HEIGHT=$(identify  -format '%h' $IMAGE)

# work directory
mkdir -p workdir

# Compile and copy binary from UFT
pushd ../../../../../sw/uft/ && make && popd
cp ../../../../../sw/uft/sender workdir/
cp ../../../../../sw/uft/receiver workdir/
cp ../../../../../sw/uft/command workdir/

# Compile and copy binary from image2file and file2image
pushd ../../../../../sw/file2image/ && make && popd
pushd ../../../../../sw/image2file/ && make && popd
cp ../../../../../sw/image2file/image2file workdir/
cp ../../../../../sw/file2image/file2image workdir/

# Compile and copy filesplit
pushd ../../wallis/testbench/filesplit/ && make && popd
cp ../../wallis/testbench/filesplit/filesplit workdir/
cp ../../wallis/testbench/filesplit/filemerge workdir/

# convert image to binary data
./workdir/image2file $IMAGE workdir/room_in.bin
# split it into files
./workdir/filesplit workdir/room_in.bin $WIDTH workdir/

# Send configuration
./workdir/command $IP 0 $WIDTH

COUNT=`expr $HEIGHT - $WIN_SIZE`
for (( c=0; c<=$COUNT; c++ ))
do
	fnamein=$(printf 'workdir/row_%03d.bin' "$c")
	fnameout=$(printf 'workdir/in_%03d.bin' "$c")
	# Start receiver in background
	workdir/receiver $fnameout &
	# Start transmitter
	workdir/sender $IP $fnameout
	# wait for receive to complete
	wait $(jobs -p)
done

# merge files
./workdir/filemerge workdir/room_out.bin workdir/in_*.bin
# convert back to image
HASH=$(git rev-parse --short HEAD)
./workdir/file2image workdir/room_out.bin workdir/room_fpga_$HASH.jpg `expr $WIDTH - $WIN_SIZE` `expr $HEIGHT - $WIN_SIZE`
# diff with sw
compare -verbose -metric MSE workdir/room_fpga_$HASH.jpg $IMAGE workdir/diff.jpg

# remove split files
rm workdir/row_*
rm workdir/in_*
