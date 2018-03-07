
.PHONY: all clean project

all:
	cd project && vivado_hls -f sobel_abs.tcl

project:
	cd project && vivado_hls -p sobel

clean:
	rm -rf project/sobel/*.*
	rm -rf project/*.log
	rm -rf project/sobel
