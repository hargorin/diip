############################################################
# Pin assignments
############################################################
# Clock and reset
set_property PACKAGE_PIN R3 [get_ports clk_in_p]
set_property PACKAGE_PIN P3 [get_ports clk_in_n]
set_property IOSTANDARD DIFF_SSTL15 [get_ports clk_in_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports clk_in_n]

set_property PACKAGE_PIN U4 [get_ports reset]
set_property IOSTANDARD SSTL15 [get_ports reset]
set_false_path -from [get_ports reset]

# PHY
set_property PACKAGE_PIN W18 [get_ports mdio_io_mdc]
set_property PACKAGE_PIN T14 [get_ports mdio_io_io]
set_property IOSTANDARD LVCMOS18 [get_ports mdio_io_mdc]
set_property IOSTANDARD LVCMOS18 [get_ports mdio_io_io]

set_property PACKAGE_PIN V14 [get_ports {rgmii_rd[3]}]
set_property PACKAGE_PIN V16 [get_ports {rgmii_rd[2]}]
set_property PACKAGE_PIN V17 [get_ports {rgmii_rd[1]}]
set_property PACKAGE_PIN U17 [get_ports {rgmii_rd[0]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {rgmii_rd[3]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {rgmii_rd[2]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {rgmii_rd[1]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {rgmii_rd[0]}]

set_property PACKAGE_PIN T17 [get_ports {rgmii_td[3]}]
set_property PACKAGE_PIN T18 [get_ports {rgmii_td[2]}]
set_property PACKAGE_PIN U15 [get_ports {rgmii_td[1]}]
set_property PACKAGE_PIN U16 [get_ports {rgmii_td[0]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {rgmii_td[3]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {rgmii_td[2]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {rgmii_td[1]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {rgmii_td[0]}]

set_property PACKAGE_PIN T15 [get_ports rgmii_tx_ctl]
set_property PACKAGE_PIN U22 [get_ports rgmii_txc]
set_property IOSTANDARD HSTL_I_18 [get_ports rgmii_tx_ctl]
set_property IOSTANDARD HSTL_I_18 [get_ports rgmii_txc]

set_property PACKAGE_PIN U14 [get_ports rgmii_rx_ctl]
set_property IOSTANDARD HSTL_I_18 [get_ports rgmii_rx_ctl]
set_property PACKAGE_PIN U21 [get_ports rgmii_rxc]
set_property IOSTANDARD HSTL_I_18 [get_ports rgmii_rxc]

set_property PACKAGE_PIN V18 [get_ports phy_resetn]
set_property IOSTANDARD HSTL_I_18 [get_ports phy_resetn]

set_property INTERNAL_VREF 0.9 [get_iobanks 13]

# User
set_property PACKAGE_PIN R8 [get_ports {speed[0]}]
set_property PACKAGE_PIN P8 [get_ports {speed[1]}]
set_property IOSTANDARD LVCMOS15 [get_ports {speed[0]}]
set_property IOSTANDARD LVCMOS15 [get_ports {speed[1]}]
set_false_path -from [get_ports {speed[0]}]
set_false_path -from [get_ports {speed[1]}]

set_property PACKAGE_PIN U6 [get_ports update_speed]
set_property IOSTANDARD LVCMOS15 [get_ports update_speed]

set_property PACKAGE_PIN M26 [get_ports led0]
set_property IOSTANDARD LVCMOS25 [get_ports led0]
set_property PACKAGE_PIN T24 [get_ports led1]
set_property IOSTANDARD LVCMOS25 [get_ports led1]
set_property PACKAGE_PIN T25 [get_ports led2]
set_property IOSTANDARD LVCMOS25 [get_ports led2]
set_property PACKAGE_PIN R26 [get_ports led3]
set_property IOSTANDARD LVCMOS25 [get_ports led3]
set_property PACKAGE_PIN U5 [get_ports SW4]
set_property IOSTANDARD LVCMOS15 [get_ports SW4]
set_property PACKAGE_PIN T5 [get_ports SW5]
set_property IOSTANDARD LVCMOS15 [get_ports SW5]

############################################################
# IODELAY
############################################################
set_property IODELAY_GROUP tri_mode_ethernet_mac_iodelay_grp [get_cells system_i/temac_support/U0/support/idelayctrl_common]


############################################################
# TIMING
############################################################
create_clock -period 5.000 -name clk_in_p [get_ports clk_in_p]
set_input_jitter clk_in_p 0.050

# Delays
# User
set_max_delay -datapath_only -from [get_ports update_speed] 4.000
# PHY
set_output_delay -clock [get_clocks -of [get_pins system_i/temac_support_0/U0/clocks/clock_generator/mmcm_adv_inst/CLKOUT1]] 1.000 [get_ports mdio_io_mdc]

############################################################
# FIFO Clock Crossing Constraints                          #
############################################################
# control signal is synched separately so this is a false path
set_max_delay -datapath_only -from [get_cells -hier -filter {name =~ *rx_fifo_i/rd_addr_reg[*]}] -to [get_cells -hier -filter {name =~ *fifo*wr_rd_addr_reg[*]}] 3.200
set_max_delay -datapath_only -from [get_cells -hier -filter {name =~ *rx_fifo_i/wr_store_frame_tog_reg}] -to [get_cells -hier -filter {name =~ *fifo_i/resync_wr_store_frame_tog/data_sync_reg0}] 3.200
set_max_delay -datapath_only -from [get_cells -hier -filter {name =~ *rx_fifo_i/update_addr_tog_reg}] -to [get_cells -hier -filter {name =~ *rx_fifo_i/sync_rd_addr_tog/data_sync_reg0}] 3.200
set_max_delay -datapath_only -from [get_cells -hier -filter {name =~ *tx_fifo_i/rd_addr_txfer_reg[*]}] -to [get_cells -hier -filter {name =~ *fifo*wr_rd_addr_reg[*]}] 3.200
set_max_delay -datapath_only -from [get_cells -hier -filter {name =~ *tx_fifo_i/wr_frame_in_fifo_reg}] -to [get_cells -hier -filter {name =~ *tx_fifo_i/resync_wr_frame_in_fifo/data_sync_reg0}] 3.200
set_max_delay -datapath_only -from [get_cells -hier -filter {name =~ *tx_fifo_i/wr_frames_in_fifo_reg}] -to [get_cells -hier -filter {name =~ *tx_fifo_i/resync_wr_frames_in_fifo/data_sync_reg0}] 3.200
set_max_delay -datapath_only -from [get_cells -hier -filter {name =~ *tx_fifo_i/frame_in_fifo_valid_tog_reg}] -to [get_cells -hier -filter {name =~ *tx_fifo_i/resync_fif_valid_tog/data_sync_reg0}] 3.200
set_max_delay -datapath_only -from [get_cells -hier -filter {name =~ *tx_fifo_i/rd_txfer_tog_reg}] -to [get_cells -hier -filter {name =~ *tx_fifo_i/resync_rd_txfer_tog/data_sync_reg0}] 3.200
set_max_delay -datapath_only -from [get_cells -hier -filter {name =~ *tx_fifo_i/rd_tran_frame_tog_reg}] -to [get_cells -hier -filter {name =~ *tx_fifo_i/resync_rd_tran_frame_tog/data_sync_reg0}] 3.200


##
## Internal paths
##
set_false_path -from [get_cells -hier -filter {name =~ *phy_resetn_int_reg}] -to [get_cells -hier -filter {name =~ *axi_lite_reset_gen/reset_sync*}]
set_false_path -to [get_pins -hier -filter {NAME =~ */reset_sync*/PRE}]
set_false_path -to [get_pins -hier -filter {NAME =~ */*_sync*/D}]


