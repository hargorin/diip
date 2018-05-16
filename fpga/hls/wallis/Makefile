
.PHONY: all clean project

all:
	cd project && vivado_hls -f wallis.tcl

project:
	cd project && vivado_hls -p wallis_proj

clean:
	rm -rf project/wallis_proj/*.*
	rm -rf project/*.log
	rm -rf project/wallis_proj
