#!/bin/bash

# clean up
make clean-sim

# get list of all testbenches
benches=$(basename $(find cores -name *tb.vhd))

echo "================================================================================"
echo " Simulation will be run for the following testbenches"
echo $benches
echo "================================================================================"

# run simulation for each testbench
for bench in $(basename $(find cores -name *tb.vhd))
do
  top=$(echo $bench  | cut -f 1 -d '.')
  echo "================================================================================"
  echo " Starting simulation for $top"
  echo "================================================================================"
  make TOP=$top sim
  make clean-sim
  echo "================================================================================"
done