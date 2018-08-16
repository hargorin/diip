#!/bin/bash

if [ "$1" = "diip" ]; then 
    echo "Building HLS based project" 
    
    # Build HLS projects
    pushd fpga/hls/
    make NAME=wallis_8b export
    make NAME=controller export
    popd

    # Build hlx project
    pushd fpga/hlx/
    make NAME=diip bit
    popd

elif [ "$1" = "diip_faster" ]; then 
    echo "Building VHDL based project" 

    # Build hlx project
    pushd fpga/hlx/
    make NAME=diip_faster bit
    popd
else
    echo "Please specify which project to build"
    echo "    ./buildall.sh diip            # to build HLS based project"
    echo "    ./buildall.sh diip_faster     # to build VHDL based project"
fi
