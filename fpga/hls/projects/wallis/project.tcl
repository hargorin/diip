# @Author: Noah
# @Date:   2018-04-27 14:46:24
# @Last Modified by:   Noah
# @Last Modified time: 2018-04-27 16:12:13

# Set the function that will be implemented
set proj_top_function wallis

# Set the clock period in [ns]
set proj_clk_period 8

# Set the clock period in [ns]
set proj_part_name "xc7a200tfbg676-2"



############################################################
## Solutions
############################################################

create_solution "sol0_wallis" "wallis" "directives_sol0.tcl"
create_solution "sol1_pixel_opt" "wallis" "directives_sol1.tcl"
create_solution "sol2_pixel_opt" "wallis" "directives_sol2.tcl"

# # Solution 0
# open_solution -reset "sol0_wallis"
# set_part {xc7a200tfbg676-2} -tool vivado
# create_clock -period 8 -name default
# source "../user/directives/directives_sol0.tcl"

# # Solution 1
# open_solution -reset "sol1_pixel_opt"
# set_part {xc7a200tfbg676-2} -tool vivado
# create_clock -period 8 -name default
# source "../user/directives/directives_sol1.tcl"

# # Solution 2
# open_solution -reset "sol2_pixel_opt"
# set_part {xc7a200tfbg676-2} -tool vivado
# create_clock -period 8 -name default
# source "../user/directives/directives_sol2.tcl"



# Settings of IP generation
set proj_vendor "ime"
set proj_library "diip"
set proj_version "0.1" 
set proj_desc "WALLIS" 
set proj_display_name "wallis"
