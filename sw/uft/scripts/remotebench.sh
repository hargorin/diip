#!/bin/bash
# @Author: Noah Huetter
# @Date:   2018-03-09 13:46:33
# @Last Modified by:   Noah Huetter
# @Last Modified time: 2018-04-05 16:58:11

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

CLIENT_IP=192.168.5.100

RED='\033[0;31m'
GRN='\033[0;32m'
NC='\033[0m' # No Color

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

# compile locally
echo "*** Local Compile"
make > /dev/null 

# Generate testfile
# base64 /dev/urandom | head -c $COUNT > infile.txt
echo "*** Gen testfile"
if [ ! -f infile.dat ]; then
    dd if=/dev/random of=infile.dat  bs=1m  count=$MBS
fi
shasum infile.dat | cut -d ' ' -f 1 > checksum

echo "*** Copy Source and complie remotely"
# Copy source and testfile to server
ssh $SRV_USER@$SRV_IP "mkdir -p $SRV_TMPDIR"
rsync -qavr -e "ssh -l $SRV_USER" --exclude 'infile*' * $SRV_IP:$SRV_TMPDIR/
# compile
ssh $SRV_USER@$SRV_IP "cd $SRV_TMPDIR && make clean && make" 2> /dev/null 

echo "*** Start Receiver"
# start receiver
ssh -f $SRV_USER@$SRV_IP "killall receiver; \
    $SRV_TMPDIR/receiver 2222 $SRV_TMPDIR/outfile.dat > /dev/null"
    # $SRV_TMPDIR/receiver 2222 $SRV_TMPDIR/outfile.dat"
sleep 0.1

echo "****************************"
echo "*** start transmit to server"
echo "****************************"
# start transmit
if [ "$machine" = "Mac" ]; then 
    # sudo dtruss -c ./sender $SRV_IP 2222 infile.dat
    ./sender $SRV_IP 2222 infile.dat
else
    ./sender $SRV_IP 2222 infile.dat  
fi;

# compare two files
ssh $SRV_USER@$SRV_IP \
    "shasum $SRV_TMPDIR/outfile.dat | cut -d ' ' -f 1 > $SRV_TMPDIR/rxchecksum;\
    if cmp --silent $SRV_TMPDIR/rxchecksum $SRV_TMPDIR/checksum; \
    then echo -e \"${GRN}Success!${NC} Files are identical (shasum match) \"; \
    else echo -e \"${RED}ERROR${NC}: Files differ\"; fi "

echo "****************************"
echo "*** start transmit to client"
echo "****************************"
# other direction
# Start receiver
killall receiver
./receiver 2222 outfile.dat &
# start transmitter
ssh $SRV_USER@$SRV_IP "killall sender; \
    $SRV_TMPDIR/sender $CLIENT_IP 2222 $SRV_TMPDIR/outfile.dat > /dev/null"
# compare
shasum outfile.dat | cut -d ' ' -f 1 > rxchecksum
if cmp --silent rxchecksum checksum
then
    echo -e "${GRN}Success!${NC} Files are identical (shasum match)"
else
    echo -e "${RED}ERROR${NC}: Files differ"
fi 
echo "****************************"

# Cleanup
echo "*** cleanup"
rm -f outfile.dat infile.txt rxchecksum
