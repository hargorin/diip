#!/bin/bash

IMAGE="room.tif"
WIN_SIZE=21

#WIDTH=$(identify  -format '%w' $IMAGE)
#HEIGHT=$(identify  -format '%h' $IMAGE)

IMAGE2FILE="../../../../../sw/image2file/image2file"
FILE2IMAGE="../../../../../sw/file2image/file2image"
WALLISFILTER="../../../../../sw/wallis_filter_datatxt_out"


WIDTH=$(identify  -format '%w' $WALLISFILTER/input_files/$IMAGE)
HEIGHT=$(identify  -format '%h' $WALLISFILTER/input_files/$IMAGE)

pushd WALLISFILTER
make clean && make
popd

pushd ../../../../../sw/file2image/
make clean && make
popd

$WALLISFILTER/wallis_filter $WALLISFILTER/input_files/$IMAGE w_room.tif > in_pixel.txt

make --directory ../../../ TOP=wallis_top_tb sim

cat ../../../build/ghdl/axi_stream_res_* | tr -d ' \n'  | xxd -r -p > out_pixel.bin
$FILE2IMAGE  out_pixel.bin out.tif `expr $HEIGHT - $WIN_SIZE + 1` `expr $WIDTH - $WIN_SIZE + 1`
