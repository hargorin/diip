# @Author: Jan Stocker
# @Date:   2018-04-27 14:46:24
# @Last Modified by:   Jan Stocker
# @Last Modified time: 2018-04-27 16:12:13

############################################################
## Solutions
############################################################

create_solution "sol0_ecc" "ecc" "directives_sol0.tcl"
create_solution "sol1_interface" "ecc" "directives_sol1.tcl"
create_solution "sol2_array_partition" "ecc" "directives_sol2.tcl"
create_solution "sol3_pipeline" "ecc" "directives_sol3.tcl"
create_solution "sol4_unroll" "ecc" "directives_sol4.tcl"
create_solution "sol5_test" "ecc" "directives_sol5.tcl"



# Add custom files
add_files -tb ../projects/ecc/input_files/landscape.jpg
add_files -tb ../projects/ecc/input_files/room.jpg
