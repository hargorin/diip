# run 'make' to build everything
# 
# Other targets:
# 	make cores
# 		Packages the IP cores
# 	
#
# 
# 


# Project name
NAME = diip_faster
# FPGA Part number
PART = xc7a200tfbg676-2

################################################################################
# Build directory
BUILD = build

# Cores to build in the ./cores directory
CORES = axi_master_burst_v2_0		\
		temac_support_v1_0 			\
		wallis_v1_0 				\
		wallis_model_v1_0 			\
		diip_controller_v1_0    	\
		udp_ip_stack_v1_0			\
		uft_stack_v2_0				\
		debounce_v1_0				\
		impulse_generator_v1_0


# Command line tools
VIVADO = vivado -nolog -nojournal -mode batch
RM = rm -rf

################################################################################
# if make is killed or interrupted during the execution of their recipes, 
# the target is not deleted
.PRECIOUS: $(BUILD)/cores/% $(BUILD)/%.xpr $(BUILD)/%.bit
.PHONY: all bit cores clean-cores project clean-project flash sim clean-sim clean impl flashqspi

all: bit

#
# Bit file
# 
bit: $(BUILD)/$(NAME).bit

# Synth and Impl only
impl: $(BUILD)/projects/$(NAME).runs/impl_1

# Synth only
synth: $(BUILD)/projects/$(NAME).runs/synth_1

#
# Project
# Depends on project sources and cores
#
project: $(addprefix $(BUILD)/cores/, $(CORES)) $(addprefix $(BUILD)/projects/, $(NAME).xpr)

clean-project:
	$(RM) $(BUILD)/projects/$(NAME)*

$(BUILD)/projects/$(NAME).xpr: projects/$(NAME)/*.tcl
	mkdir -p $(@D)
	$(VIVADO) -source scripts/project.tcl -tclargs $(NAME) $(PART) $(BUILD)/projects/ $(BUILD)/cores/

#
# Cores
# Depend on core hdl sources
# 
cores: $(addprefix $(BUILD)/cores/, $(CORES))

clean-cores:
	$(RM) $(BUILD)/cores/*

$(BUILD)/cores/%: cores/%/core_config.tcl cores/%/hdl/*.vhd
	mkdir -p $(@D)
	cp cores/$*/*.xml $(BUILD)/cores/  || :
	$(VIVADO) -source scripts/core.tcl -tclargs $* $(PART) $(BUILD)/cores/


#
# Synth and impl
# 
$(BUILD)/projects/$(NAME).runs/impl_1: $(addprefix $(BUILD)/cores/, $(CORES)) $(BUILD)/projects/$(NAME).xpr
	$(VIVADO) -source scripts/synthimpl.tcl -tclargs $(NAME) $(BUILD)/projects/
#
# impl
# 
$(BUILD)/projects/$(NAME).runs/synth_1: $(addprefix $(BUILD)/cores/, $(CORES)) $(BUILD)/projects/$(NAME).xpr
	$(VIVADO) -source scripts/synth.tcl -tclargs $(NAME) $(BUILD)/projects/

#
# Bitstream
# Depends on the project tcl and cores
# This synthesizes and implements the design
# 
$(BUILD)/$(NAME).bit: $(addprefix $(BUILD)/cores/, $(CORES)) $(BUILD)/projects/$(NAME).xpr $(BUILD)/projects/$(NAME).runs/impl_1
	mkdir -p $(@D)
	$(VIVADO) -source scripts/bitstream.tcl -tclargs $(NAME) $(BUILD)/projects/ $(BUILD)/

#
# Flash
# 
flash: $(BUILD)/$(NAME).bit
	$(VIVADO) -source scripts/flash.tcl -tclargs $(NAME) $(BUILD)/projects/ $(BUILD)/

#
# Flash QSPI
# 
flashqspi: $(BUILD)/$(NAME).bit
	$(VIVADO) -source scripts/flashqspi.tcl -tclargs $(NAME) $(BUILD)/projects/ $(BUILD)/

#
# Simulation
# 
LASTTOP:=$(shell cat $(BUILD)/ghdl/stamp 2>/dev/null)
sim:
ifeq ($(LASTTOP),$(TOP))
	$(RM) $(BUILD)/ghdl/*.log
	cd $(BUILD)/ghdl/ && $(MAKE) run
else
	$(RM) $(BUILD)/ghdl/*
	scripts/configure_ghdl.sh ${TOP}
	@echo "$(TOP)" > $(BUILD)/ghdl/stamp
	cd $(BUILD)/ghdl/ && $(MAKE) run
endif
ifeq ($(TOP),uft_top_tb)
	./simulation/uftcheck.py -e $(BUILD)/ghdl/axi_stream_res*.log
	./simulation/uftvalidate.sh
endif

clean-sim:
	$(RM) $(BUILD)/ghdl/*


#
# clean
# 
clean:
	$(RM) $(BUILD)
	$(RM) vivado*.jou vivado*.log
