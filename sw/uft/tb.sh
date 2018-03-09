#!/bin/bash
# @Author: Noah Huetter
# @Date:   2018-03-09 13:46:33
# @Last Modified by:   Noah Huetter
# @Last Modified time: 2018-03-09 14:14:55

# Runs a local loopback UFT test transmission using base64 data

##
## How many characters to transmit
##
COUNT=1000000   

# Generate testfile
base64 /dev/urandom | head -c $COUNT > infile.txt

# start receiver
./receiver 2222 outfile.txt &
rx_pid=$!
sleep 0.1

# start transmit
./sender 127.0.0.1 2222 infile.txt

# Wait for complete
# while ps | grep " $rx_pid "     # might also need  | grep -v grep  here
# do
#     echo $rx_pid is still in the ps output. Must still be running.
#     sleep 1
# done

# compare two files
cmp --silent infile.txt outfile.txt || echo "ERROR: Files differ"

# Cleanup
rm infile.txt outfile.txt
