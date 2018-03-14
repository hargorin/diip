#!/bin/bash
# @Author: Noah Huetter
# @Date:   2018-03-09 13:46:33
# @Last Modified by:   Noah Huetter
# @Last Modified time: 2018-03-14 14:00:53

# Runs a UFT test transmission to a server in the network

##
## How many characters to transmit
##
COUNT=1000000   

##
## Server settings
## Must have ssh enabled
##
SRV_IP=192.168.5.32
SRV_USER=noah
SRV_TMPDIR=/tmp/uft

# Generate testfile
base64 /dev/urandom | head -c $COUNT > infile.txt

# Copy source and testfile to server
ssh $SRV_USER@$SRV_IP "mkdir -p $SRV_TMPDIR"
scp -q -r * $SRV_USER@$SRV_IP:$SRV_TMPDIR/

# compile
ssh $SRV_USER@$SRV_IP "cd $SRV_TMPDIR && make clean && make"

# start receiver
ssh -f $SRV_USER@$SRV_IP "$SRV_TMPDIR/receiver 2222 $SRV_TMPDIR/outfile.txt"
sleep 0.1

# start transmit
./sender $SRV_IP 2222 infile.txt

# Wait for complete
# while ps | grep " $rx_pid "     # might also need  | grep -v grep  here
# do
#     echo $rx_pid is still in the ps output. Must still be running.
#     sleep 1
# done

# compare two files
ssh $SRV_USER@$SRV_IP \
    "cmp --silent $SRV_TMPDIR/infile.txt $SRV_TMPDIR/outfile.txt \
    || echo \"ERROR: Files differ\""

# Cleanup
rm infile.txt
