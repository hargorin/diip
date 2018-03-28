#!/bin/bash
# @Author: Noah Huetter
# @Date:   2018-03-09 13:46:33
# @Last Modified by:   Noah Huetter
# @Last Modified time: 2018-03-21 15:55:26

# Runs a UFT test transmission to a server in the network

##
## How many characters to transmit
##
# COUNT=100000000
MBS=100

##
## Server settings
## Must have ssh enabled
##
SRV_IP=192.168.5.32
SRV_USER=noah
SRV_TMPDIR=/tmp/uft

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac
echo ${machine}

# compile locally
make

# Generate testfile
# base64 /dev/urandom | head -c $COUNT > infile.txt
if [ ! -f infile.dat ]; then
    dd if=/dev/random of=infile.dat  bs=1m  count=$MBS
fi
shasum infile.dat | cut -d ' ' -f 1 > checksum

# Copy source and testfile to server
ssh $SRV_USER@$SRV_IP "mkdir -p $SRV_TMPDIR"
# scp -q -r * $SRV_USER@$SRV_IP:$SRV_TMPDIR/
rsync -qavr -e "ssh -l $SRV_USER" --exclude 'infile*' * $SRV_IP:$SRV_TMPDIR/

# compile
ssh $SRV_USER@$SRV_IP "cd $SRV_TMPDIR && make clean && make"

# start receiver
ssh -f $SRV_USER@$SRV_IP "killall receiver; \
    $SRV_TMPDIR/receiver 2222 $SRV_TMPDIR/outfile.dat > /dev/null"
    # $SRV_TMPDIR/receiver 2222 $SRV_TMPDIR/outfile.dat"
sleep 0.1

# start transmit
if [ "$machine" = "Mac" ]; then 
    # sudo dtruss -c ./sender $SRV_IP 2222 infile.dat
    ./sender $SRV_IP 2222 infile.dat
else
    ./sender $SRV_IP 2222 infile.dat  
fi;

# Wait for complete
# while ps | grep " $rx_pid "     # might also need  | grep -v grep  here
# do
#     echo $rx_pid is still in the ps output. Must still be running.
#     sleep 1
# done

# compare two files

# ssh $SRV_USER@$SRV_IP \
#     "if cmp --silent $SRV_TMPDIR/infile.txt $SRV_TMPDIR/outfile.txt; \
#     then echo \"Success! Files are identical\"; \
#     else echo \"ERROR: Files differ\"; fi "
ssh $SRV_USER@$SRV_IP \
    "shasum $SRV_TMPDIR/outfile.dat | cut -d ' ' -f 1 > $SRV_TMPDIR/rxchecksum;\
    if cmp --silent $SRV_TMPDIR/rxchecksum $SRV_TMPDIR/checksum; \
    then echo \"Success! Files are identical (shasum match) \"; \
    else echo \"ERROR: Files differ\"; fi "

# Cleanup
rm -f infile.txt
