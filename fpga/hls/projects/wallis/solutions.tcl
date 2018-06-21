# @Author: Noah
# @Date:   2018-04-27 14:46:24
# @Last Modified by:   Jan
# @Last Modified time: 2018-06-21 16:12:13

############################################################
## Solutions
############################################################

create_solution "sol0_wallis" "wallis" "directives_sol0.tcl"
create_solution "sol1_pixel_opt" "wallis" "directives_sol1.tcl"
create_solution "sol2_pixel_opt" "wallis" "directives_sol2.tcl"
create_solution "sol10_LUT_opt" "wallis" "directives_sol10.tcl"
create_solution "sol11_ecc" "wallis" "directives_sol11.tcl"
create_solution "sol12_stream256" "wallis" "directives_sol12.tcl"
create_solution "sol13_lessFF_moreBRAM" "wallis" "directives_sol13.tcl"
create_solution "sol14_S2P_BRAM" "wallis" "directives_sol14.tcl"
create_solution "sol15_S2P_LUTRAM" "wallis" "directives_sol15.tcl"
create_solution "sol16_T2P_BRAM" "wallis" "directives_sol16.tcl"


# Add custom files
add_files -tb ../projects/wallis/input_files/landscape.jpg
add_files -tb ../projects/wallis/input_files/room.jpg
add_files -tb ../projects/wallis/input_files/room32x32.jpg
add_files -tb ../projects/wallis/input_files/room128x128.jpg
add_files -tb ../projects/wallis/input_files/room256x256.jpg
