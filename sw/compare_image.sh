#!/bin/sh

cd image2file
make && ./image2file input_files/room.png out/room.bin

cd ../file2image
make && ./file2image ../image2file/out/room.bin out/room.png 680 558

cd ../
compare image2file/input_files/room.png file2image/out/room.png diff.png
display diff.png
