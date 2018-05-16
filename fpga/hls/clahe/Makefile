
.PHONY: all clean project

all:
	cd project && vivado_hls -f clahe.tcl

project:
	cd project && vivado_hls -p clahe_proj

clean:
	rm -rf project/clahe_proj/*.*
	rm -rf project/*.log
	rm -rf project/clahe_proj
