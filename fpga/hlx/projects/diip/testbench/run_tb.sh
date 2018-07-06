#!/bin/bash

# Input arguments
IP="192.168.5.9"
# IMAGE="images/room256x256.jpg"
IMAGE="images/mountain_medium.tif"
WIN_SIZE=21

# Get information
WIDTH=$(identify  -format '%w' $IMAGE)
HEIGHT=$(identify  -format '%h' $IMAGE)

# work directory
mkdir -p workdir/split/

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

# Clean up before starting
rm workdir/split/*


# convert image to binary data
./workdir/image2file $IMAGE workdir/room_in.bin
# split it into files
./workdir/filesplit workdir/room_in.bin $WIDTH workdir/split/

# Send configuration
./workdir/command $IP 0 $WIDTH


########################################################################
##
## Send same row 16 times
##
########################################################################
# vivado -nolog -nojournal -mode batch -source diip_tb.tcl -tclargs tb3

# # Diff row and ii*
# NOMATCH=0
# for file in workdir/split/ii_000_*; do
#     DIFF=$(diff "workdir/split/row_000.bin" "$file")
# 	if [ "$DIFF" != "" ] 
# 	then
# 	    NOMATCH=$[$NOMATCH+1]
# 	fi
# done
# echo "$NOMATCH PC->FPGA->PC files differ"

# # Diff in* and ij*
# NOMATCH=0
# for ((c=0; c<16; c++))
# do 
# 	f1=$(printf 'workdir/split/in_000_%02d.bin' "$c")
# 	f2=$(printf 'workdir/split/ij_000_%02d.bin' "$c")
# 	DIFF=$(diff $f1 $f2) 
# 	if [ "$DIFF" != "" ] 
# 	then
# 	    NOMATCH=$[$NOMATCH+1]
# 	fi
# done
# echo "$NOMATCH PC->FPGA->WALLIS->PC files differ"

########################################################################
##
## TB with JTAG AXI validation: copy to FPGA, run wallis and copy back
##
########################################################################
# vivado -nolog -nojournal -mode batch -source diip_tb.tcl -tclargs tb2
# ./workdir/filemerge workdir/room_out_jtag.bin workdir/split/ij_*.bin
# ./workdir/filemerge workdir/room_out.bin workdir/split/in_*.bin
# ./workdir/filemerge workdir/room_in_jtag.bin workdir/split/ii_*.bin

# echo "---------------------------------------"
# echo "Starting diff PC->FPGA->PC"
# NOMATCH=0
# COUNT=`expr $HEIGHT - $WIN_SIZE + 1`
# for ((c=0; c<$COUNT; c++))
# do 
# 	f1=$(printf 'workdir/split/row_%03d.bin' "$c")
# 	f2=$(printf 'workdir/split/ii_%03d.bin' "$c")
# 	DIFF=$(diff $f1 $f2) 
# 	if [ "$DIFF" != "" ] 
# 	then
# 	    NOMATCH=$[$NOMATCH+1]
# 	fi
# done
# if [ "$NOMATCH" != 0 ] 
# then
#     echo "$NOMATCH of $COUNT files differ"
# else
# 	echo "All $COUNT files are identical"
# fi
# echo "---------------------------------------"

# echo "---------------------------------------"
# echo "Starting in diff PC->FPGA->WALLIS->PC"
# NOMATCH=0
# for ((c=0; c<$COUNT; c++))
# do 
# 	f1=$(printf 'workdir/split/in_%03d.bin' "$c")
# 	f2=$(printf 'workdir/split/ij_%03d.bin' "$c")
# 	DIFF=$(diff $f1 $f2) 
# 	if [ "$DIFF" != "" ] 
# 	then
# 	    NOMATCH=$[$NOMATCH+1]
# 	fi
# done
# if [ "$NOMATCH" != 0 ] 
# then
#     echo "$NOMATCH of $COUNT files differ"
# else
# 	echo "All $COUNT files are identical"
# fi
# echo "---------------------------------------"

# HASH=$(git rev-parse --short HEAD)
# ./workdir/file2image workdir/room_out_jtag.bin workdir/room_fpga_jtag_$HASH.jpg `expr $WIDTH - $WIN_SIZE + 1` `expr $HEIGHT - $WIN_SIZE + 1` -s
# ./workdir/file2image workdir/room_out.bin workdir/room_fpga_$HASH.jpg `expr $WIDTH - $WIN_SIZE + 1` `expr $HEIGHT - $WIN_SIZE + 1` -s

########################################################################
##
## True TB
##
########################################################################
COUNT=`expr $HEIGHT - $WIN_SIZE + 1`
for (( c=0; c<$COUNT; ))
do
	fnamein=$(printf 'workdir/split/row_%03d.bin' "$c")
	fnameout=$(printf 'workdir/split/in_%03d.bin' "$c")
	# Status
	echo "c = $c"
	# Start receiver in background
	nohup workdir/receiver 2222 $fnameout &
	pid=$!
	# Start transmitter
	nohup workdir/sender $IP 42042 $fnamein
	# Give the data change to receive
	# sleep 0.5
	# If receiver still running, kill it and try again
	ps -p $pid > /dev/null
	if [ $? == 1 ]; then
	    echo "Data received"
	    c=$[c+1]
	else
	    echo "Data not received"
	    kill $pid
	fi
done

# merge files
./workdir/filemerge workdir/room_out.bin workdir/split/in_*.bin
# convert back to image
HASH=$(git rev-parse --short HEAD)
./workdir/file2image workdir/room_out.bin workdir/room_fpga_$HASH.jpg `expr $HEIGHT - $WIN_SIZE + 1` `expr $WIDTH - $WIN_SIZE + 1` -s
# diff with sw
compare -verbose -metric MSE workdir/room_fpga_$HASH.jpg images/wallis_hw_room128x128.jpg workdir/diff.jpg


########################################################################
##
## UFT local test
##
########################################################################
# COUNT=`expr $HEIGHT - $WIN_SIZE + 1`
# for (( c=0; c<$COUNT; ))
# do
# 	fnamein=$(printf 'workdir/split/row_%03d.bin' "$c")
# 	fnameout=$(printf 'workdir/split/rol_%03d.bin' "$c")
# 	# Start receiver in background
# 	nohup workdir/receiver 2222 $fnameout &
# 	pid=$!
# 	# Start transmitter
# 	nohup workdir/sender 192.168.5.10 2222 $fnamein
# 	# Give the data change to receive
# 	# sleep 0.5
# 	# If receiver still running, kill it and try again
# 	ps -p $pid > /dev/null
# 	if [ $? == 1 ]; then
# 	    echo "Data received"
# 	    c=$[c+1]
# 	else
# 	    echo "Data not received"
# 	    kill $pid
# 	fi
# done

# echo "---------------------------------------"
# echo "Starting diff all"
# for ((c=0; c<$COUNT; c++))
# do 
# 	f1=$(printf 'workdir/split/row_%03d.bin' "$c")
# 	f2=$(printf 'workdir/split/rol_%03d.bin' "$c")
# 	diff $f1 $f2
# done
# echo "---------------------------------------"
