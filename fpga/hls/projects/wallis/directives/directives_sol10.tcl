############################################################
## This file is generated automatically by Vivado HLS.
## Please DO NOT edit it.
## Copyright (C) 1986-2017 Xilinx, Inc. All Rights Reserved.
############################################################
set_directive_interface -mode axis -register -register_mode reverse "wallis" inData
set_directive_interface -mode axis -register -register_mode forward "wallis" outData
set_directive_interface -mode s_axilite -bundle params "wallis" g_Mean
set_directive_interface -mode s_axilite -bundle params "wallis" g_Var
set_directive_interface -mode s_axilite -bundle params "wallis" contrast
set_directive_interface -mode s_axilite -bundle params "wallis" brightness
set_directive_inline "Cal_Mean"
set_directive_inline "Cal_Variance"
set_directive_inline "Wallis_Filter"
set_directive_unroll "Cal_Mean"
set_directive_pipeline "wallis/loop_rdata"
set_directive_unroll -factor 21 "Cal_Variance/loop_variance"
set_directive_dependence -variable n_Mean -type inter -direction RAW -dependent true "wallis"
set_directive_dependence -variable n_Var -type inter -direction RAW -dependent true "wallis"
set_directive_unroll -factor 21 "wallis/loop_strData"
set_directive_pipeline "wallis/loop_addData"
set_directive_unroll -factor 21 "wallis/loop_setData"
set_directive_pipeline "Cal_Variance/loop_variance"
set_directive_pipeline "wallis/loop_setData"
set_directive_pipeline "wallis/loop_strData"
set_directive_loop_flatten -off "wallis/loop_while"
set_directive_loop_tripcount -min 110 -max 1640 -avg 420 "wallis/loop_while"
set_directive_array_partition -type cyclic -factor 21 -dim 1 "wallis" pixel
set_directive_array_partition -type cyclic -factor 21 -dim 1 "wallis" tmp_Pixel
set_directive_resource -core RAM_2P_BRAM "wallis" pixel
set_directive_resource -core RAM_2P_BRAM "wallis" tmp_Pixel
set_directive_interface -mode ap_ctrl_none "wallis"
