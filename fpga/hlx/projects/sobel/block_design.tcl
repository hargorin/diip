# ================================================================================
# block_design.tcl
# 
# Creates the block design
# 
# Can be copy-pasted from the output of vivados block design export to tcl
# 
# by Noah Huetter <noahhuetter@gmail.com>
# ================================================================================
# @Author: Noah Huetter
# @Date:   2017-11-24 15:21:33
# @Last Modified by:   Noah Huetter
# @Last Modified time: 2017-12-06 11:53:13

##
## Place Cells
##

# 4 BRAM Controller
set n 4
for {set i 0} {$i < $n} {incr i} {
    set vlnv xilinx.com:ip:axi_bram_ctrl:4.0
    set name axi_bram_ctrl_$i
    cell $vlnv $name {
            SINGLE_PORT_BRAM {1}
        } {}
}

# AXI GPIO for start signa;
set vlnv xilinx.com:ip:axi_gpio:2.0
set name axi_gpio_0
cell $vlnv $name {
        C_ALL_OUTPUTS {1}
        C_GPIO_WIDTH {1}
    } {}

# AXI Interconnect
set vlnv xilinx.com:ip:axi_interconnect:2.1
set name axi_mem_intercon
cell $vlnv $name {
        NUM_MI {5}
    } {}
# 4 BRAM generator
set n 4
for {set i 0} {$i < $n} {incr i} {
    set vlnv xilinx.com:ip:blk_mem_gen:8.3
    set name blk_mem_gen_$i
    cell $vlnv $name {
            Enable_B {Use_ENB_Pin}
            Memory_Type {True_Dual_Port_RAM}
            Port_B_Clock {100}
            Port_B_Enable_Rate {100}
            Port_B_Write_Rate {50}
            Use_RSTB_Pin {true}
        } {}
}

# Clocking wizard
set vlnv xilinx.com:ip:clk_wiz:5.4
set name clk_wiz
cell $vlnv $name {
        CLKIN1_JITTER_PS {50.0}
        CLKOUT1_JITTER {112.316}
        CLKOUT1_PHASE_ERROR {89.971}
        CLK_IN1_BOARD_INTERFACE {sys_diff_clock}
        MMCM_CLKFBOUT_MULT_F {5.000}
        MMCM_CLKIN1_PERIOD {5.000}
        MMCM_CLKIN2_PERIOD {10.0}
        MMCM_DIVCLK_DIVIDE {1}
        PRIM_SOURCE {Differential_clock_capable_pin}
        RESET_BOARD_INTERFACE {reset}
        USE_BOARD_FLOW {true}
    } {}

# System reset
set vlnv xilinx.com:ip:proc_sys_reset:5.0
set name rst_clk_wiz_100M
cell $vlnv $name {
        RESET_BOARD_INTERFACE {reset}
        USE_BOARD_FLOW {true}
    } {}

# JTAG to AXI
set vlnv xilinx.com:ip:jtag_axi:1.2
set name jtag_axi_0
cell $vlnv $name {} {}

# Sobel instance
set vlnv ime:image_processing:sobel_abs:1.1
set name sobel_abs_0
cell $vlnv $name {} {}

delete_bd_objs [get_bd_ports SW4]
delete_bd_objs [get_bd_ports update_speed]
delete_bd_objs [get_bd_ports speed]
delete_bd_objs [get_bd_ports led0]
delete_bd_objs [get_bd_intf_ports mdio_io]
delete_bd_objs [get_bd_intf_ports rgmii]
delete_bd_objs [get_bd_ports phy_resetn]

##
## Create Connections
##
# Create interface connections
connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]
connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_1/BRAM_PORTA]
connect_bd_intf_net -intf_net axi_bram_ctrl_2_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_2/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_2/BRAM_PORTA]
connect_bd_intf_net -intf_net axi_bram_ctrl_3_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_3/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_3/BRAM_PORTA]
connect_bd_intf_net -intf_net axi_mem_intercon_M00_AXI [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] [get_bd_intf_pins axi_mem_intercon/M00_AXI]
connect_bd_intf_net -intf_net axi_mem_intercon_M01_AXI [get_bd_intf_pins axi_bram_ctrl_1/S_AXI] [get_bd_intf_pins axi_mem_intercon/M01_AXI]
connect_bd_intf_net -intf_net axi_mem_intercon_M02_AXI [get_bd_intf_pins axi_bram_ctrl_2/S_AXI] [get_bd_intf_pins axi_mem_intercon/M02_AXI]
connect_bd_intf_net -intf_net axi_mem_intercon_M03_AXI [get_bd_intf_pins axi_bram_ctrl_3/S_AXI] [get_bd_intf_pins axi_mem_intercon/M03_AXI]
connect_bd_intf_net -intf_net axi_mem_intercon_M04_AXI [get_bd_intf_pins axi_gpio_0/S_AXI] [get_bd_intf_pins axi_mem_intercon/M04_AXI]
connect_bd_intf_net -intf_net jtag_axi_0_M_AXI [get_bd_intf_pins axi_mem_intercon/S00_AXI] [get_bd_intf_pins jtag_axi_0/M_AXI]
connect_bd_intf_net -intf_net sobel_abs_0_cal_pixel_PORTA [get_bd_intf_pins blk_mem_gen_3/BRAM_PORTB] [get_bd_intf_pins sobel_abs_0/cal_pixel_PORTA]
connect_bd_intf_net -intf_net sobel_abs_0_pixel_r0_PORTA [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTB] [get_bd_intf_pins sobel_abs_0/pixel_r0_PORTA]
connect_bd_intf_net -intf_net sobel_abs_0_pixel_r1_PORTA [get_bd_intf_pins blk_mem_gen_1/BRAM_PORTB] [get_bd_intf_pins sobel_abs_0/pixel_r1_PORTA]
connect_bd_intf_net -intf_net sobel_abs_0_pixel_r2_PORTA [get_bd_intf_pins blk_mem_gen_2/BRAM_PORTB] [get_bd_intf_pins sobel_abs_0/pixel_r2_PORTA]

# Create port connections
connect_bd_net -net axi_gpio_0_gpio_io_o [get_bd_pins axi_gpio_0/gpio_io_o] [get_bd_pins sobel_abs_0/ap_start]
connect_bd_net -net clk_in1_n_1 [get_bd_ports clk_in_n] [get_bd_pins clk_wiz/clk_in1_n]
connect_bd_net -net clk_in1_p_1 [get_bd_ports clk_in_p] [get_bd_pins clk_wiz/clk_in1_p]
connect_bd_net -net clk_wiz_clk_out1 [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_bram_ctrl_1/s_axi_aclk] [get_bd_pins axi_bram_ctrl_2/s_axi_aclk] [get_bd_pins axi_bram_ctrl_3/s_axi_aclk] [get_bd_pins axi_gpio_0/s_axi_aclk] [get_bd_pins axi_mem_intercon/ACLK] [get_bd_pins axi_mem_intercon/M00_ACLK] [get_bd_pins axi_mem_intercon/M01_ACLK] [get_bd_pins axi_mem_intercon/M02_ACLK] [get_bd_pins axi_mem_intercon/M03_ACLK] [get_bd_pins axi_mem_intercon/M04_ACLK] [get_bd_pins axi_mem_intercon/S00_ACLK] [get_bd_pins clk_wiz/clk_out1] [get_bd_pins jtag_axi_0/aclk] [get_bd_pins rst_clk_wiz_100M/slowest_sync_clk] [get_bd_pins sobel_abs_0/ap_clk]
connect_bd_net -net clk_wiz_locked [get_bd_pins clk_wiz/locked] [get_bd_pins rst_clk_wiz_100M/dcm_locked]
connect_bd_net -net reset_1 [get_bd_ports reset] [get_bd_pins clk_wiz/reset] [get_bd_pins rst_clk_wiz_100M/ext_reset_in]
connect_bd_net -net rst_clk_wiz_100M_interconnect_aresetn [get_bd_pins axi_mem_intercon/ARESETN] [get_bd_pins rst_clk_wiz_100M/interconnect_aresetn]
connect_bd_net -net rst_clk_wiz_100M_peripheral_aresetn [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_1/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_2/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_3/s_axi_aresetn] [get_bd_pins axi_gpio_0/s_axi_aresetn] [get_bd_pins axi_mem_intercon/M00_ARESETN] [get_bd_pins axi_mem_intercon/M01_ARESETN] [get_bd_pins axi_mem_intercon/M02_ARESETN] [get_bd_pins axi_mem_intercon/M03_ARESETN] [get_bd_pins axi_mem_intercon/M04_ARESETN] [get_bd_pins axi_mem_intercon/S00_ARESETN] [get_bd_pins jtag_axi_0/aresetn] [get_bd_pins rst_clk_wiz_100M/peripheral_aresetn]
connect_bd_net -net rst_clk_wiz_100M_peripheral_reset [get_bd_pins rst_clk_wiz_100M/peripheral_reset] [get_bd_pins sobel_abs_0/ap_rst]

# Create address segments
create_bd_addr_seg -range 0x00001000 -offset 0xC0000000 [get_bd_addr_spaces jtag_axi_0/Data] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] SEG_axi_bram_ctrl_0_Mem0
create_bd_addr_seg -range 0x00001000 -offset 0xC2000000 [get_bd_addr_spaces jtag_axi_0/Data] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0] SEG_axi_bram_ctrl_1_Mem0
create_bd_addr_seg -range 0x00001000 -offset 0xC4000000 [get_bd_addr_spaces jtag_axi_0/Data] [get_bd_addr_segs axi_bram_ctrl_2/S_AXI/Mem0] SEG_axi_bram_ctrl_2_Mem0
create_bd_addr_seg -range 0x00001000 -offset 0xC6000000 [get_bd_addr_spaces jtag_axi_0/Data] [get_bd_addr_segs axi_bram_ctrl_3/S_AXI/Mem0] SEG_axi_bram_ctrl_3_Mem0
create_bd_addr_seg -range 0x00001000 -offset 0x40000000 [get_bd_addr_spaces jtag_axi_0/Data] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] SEG_axi_gpio_0_Reg




