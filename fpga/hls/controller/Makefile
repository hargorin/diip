
.PHONY: all clean project

all:
	cd project && vivado_hls -f controller_proj.tcl

project:
	cd project && vivado_hls -p controller

clean:
	rm -rf project/controller/*.*
	rm -rf project/*.log
	rm -rf project/controller
