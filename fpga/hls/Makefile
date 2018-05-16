# ================================================================================
# Vivado HLS Makefile
# 
# by Noah Huetter <noahhuetter@gmail.com>
# ================================================================================
# Default Target: export
# 	Runts synthesis, cosimulation and export to IP core
# ================================================================================

# Project name
NAME = wallis
# SOLUTION = sol_0
SOLUTION = $(grep proj_top_solution projects/$(NAME)/project.tcl | awk '{print $3}')
# FPGA Part number
PART = xc7a200tfbg676-2

################################################################################
# Build directory
BUILD = build

# Command line tools
VIVADO_HLS = vivado_hls -f
RM = rm -rf
################################################################################

.PHONY: all clean project csim synth cosim export

all: export

#-------------------------------------------------------------------------------
project: $(BUILD)/$(NAME)/vivado_hls.app
$(BUILD)/$(NAME)/vivado_hls.app: projects/$(NAME)/project.tcl
	mkdir -p $(BUILD)
	cd $(BUILD) && $(VIVADO_HLS) ../scripts/project.tcl -tclargs $(NAME) $(PART) .

#-------------------------------------------------------------------------------
csim: $(BUILD)/$(NAME)/$(SOLUTION)/csim
$(BUILD)/$(NAME)/$(SOLUTION)/csim: projects/$(NAME)/src/* projects/$(NAME)/bench/* $(BUILD)/$(NAME)/vivado_hls.app
	cd $(BUILD)/ && $(VIVADO_HLS) ../scripts/csim.tcl -tclargs $(NAME)

#-------------------------------------------------------------------------------
synth: $(BUILD)/$(NAME)/$(SOLUTION)/syn/vhdl
$(BUILD)/$(NAME)/$(SOLUTION)/syn/vhdl: $(BUILD)/$(NAME)/vivado_hls.app projects/$(NAME)/src/*
	cd $(BUILD)/ && $(VIVADO_HLS) ../scripts/synth.tcl -tclargs $(NAME)

#-------------------------------------------------------------------------------
cosim: $(BUILD)/$(NAME)/$(SOLUTION)/sim
$(BUILD)/$(NAME)/$(SOLUTION)/sim: $(BUILD)/$(NAME)/$(SOLUTION)/syn/vhdl
	cd $(BUILD)/ && $(VIVADO_HLS) ../scripts/cosim.tcl -tclargs $(NAME)

#-------------------------------------------------------------------------------
export: $(BUILD)/$(NAME)/$(SOLUTION)/impl/ip
$(BUILD)/$(NAME)/$(SOLUTION)/impl/ip: $(BUILD)/$(NAME)/$(SOLUTION)/syn/vhdl
	cd $(BUILD)/ && $(VIVADO_HLS) ../scripts/exportip.tcl -tclargs $(NAME)

#-------------------------------------------------------------------------------
clean:
	$(RM) $(BUILD)/$(NAME)
clean-synth:
	$(RM) $(BUILD)/$(NAME)/sol_0/syn
clean-sim:
	$(RM) $(BUILD)/$(NAME)/sol_0/sim
clean-all:
	$(RM) $(BUILD)
