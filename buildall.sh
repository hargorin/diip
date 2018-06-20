#!/bin/bash

# Build HLS projects
pushd fpga/hls/
make NAME=wallis export
make NAME=controller export
popd

# Build hlx project
pushd fpga/hlx/
make NAME=diip bit
popd
