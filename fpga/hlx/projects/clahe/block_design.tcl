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
create_bd_cell -type ip -vlnv ime:image_processing:clahe:0.0 clahe_0