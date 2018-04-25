
.PHONY: all clean project

# Core and project Name
NAME = stream_dummy
# Core top function
TOP = $(NAME)_top

all:
	cd project && vivado_hls -f $(NAME)_proj.tcl

project:
	cd project && vivado_hls -p $(NAME)

clean:
	rm -rf project/$(NAME)/*.*
	rm -rf project/*.log
	rm -rf project/$(NAME)
