#!/bin/bash

# work directory
mkdir -p workdir

# Compile and copy binary from UFT
pushd ../../../../../sw/uft/ && make && popd
cp ../../../../../sw/uft/sender workdir/
cp ../../../../../sw/uft/receiver workdir/
cp ../../../../../sw/uft/command workdir/

# Write some user registers
./workdir/command 192.168.5.9 0 1024
./workdir/command 192.168.5.9 1 1
./workdir/command 192.168.5.9 6 0xaffe
./workdir/command 192.168.5.9 7 0xffffeeee

# Start receiver in background
./workdir/receiver 2222 workdir/out.txt &

# Run TCL testbench
vivado -nolog -nojournal -mode batch -source comm_tb.tcl

# wait for receive to complete
wait $(jobs -p)

echo "------ Sent data is"
cat payload.txt
echo "------ Received data is"
cat workdir/out.txt
