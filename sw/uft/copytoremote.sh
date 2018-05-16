#!/bin/bash
# @Author: Noah Huetter
# @Date:   2018-03-09 13:46:33
# @Last Modified by:   Noah Huetter
# @Last Modified time: 2018-03-28 12:39:24

# Copy working directory to server

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

# Copy source and testfile to server
ssh $SRV_USER@$SRV_IP "mkdir -p $SRV_TMPDIR"
# scp -q -r * $SRV_USER@$SRV_IP:$SRV_TMPDIR/
rsync -qavr -e "ssh -l $SRV_USER" --exclude 'infile*' * $SRV_IP:$SRV_TMPDIR/

# compile remotely
ssh $SRV_USER@$SRV_IP "cd $SRV_TMPDIR && make clean && make"
