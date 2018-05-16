#!/bin/bash
# @Author: Noah Huetter
# @Date:   2018-04-05 17:52:38
# @Last Modified by:   Noah Huetter
# @Last Modified time: 2018-04-05 17:55:40


rm log.txt

# Run 10 times
for i in `seq 1 10`;
do
    echo $i
    ./sender 192.168.5.32 2222 infile.dat >> log.txt
    sleep 2
done  


