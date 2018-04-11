
.PHONY: all clean project

all:
	cd project && vivado_hls -f clahe.tcl

project:
	cd project && vivado_hls -p clahe

clean:
	rm -rf project/clahe/*.*
	rm -rf project/*.log
	rm -rf project/clahe
