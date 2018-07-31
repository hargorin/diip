############################################################
## This file is generated automatically by Vivado HLS.
## Please DO NOT edit it.
## Copyright (C) 1986-2017 Xilinx, Inc. All Rights Reserved.
############################################################
set_directive_interface -mode axis -register -register_mode reverse "wallis" inData
set_directive_interface -mode axis -register -register_mode forward "wallis" outData
set_directive_interface -mode s_axilite -bundle ctrl "wallis" g_Mean
set_directive_interface -mode s_axilite -bundle ctrl "wallis" g_Var
set_directive_interface -mode s_axilite -bundle ctrl "wallis" contrast
set_directive_interface -mode s_axilite -bundle ctrl "wallis" brightness
set_directive_interface -mode s_axilite -bundle ctrl "wallis"
set_directive_resource -core RAM_2P_BRAM "wallis" pixel
set_directive_inline "Cal_Mean"
set_directive_inline "Cal_Variance"
set_directive_pipeline "wallis/loop_rdata"
set_directive_loop_flatten -off "wallis/loop_while"
set_directive_loop_tripcount -min 1 -max 679 "wallis/loop_while"
set_directive_unroll "wallis/loop_subData"
set_directive_unroll "wallis/loop_strData"
set_directive_unroll "wallis/loop_sum"
set_directive_array_partition -type complete "wallis" pixel
set_directive_unroll "wallis/loop_addData"
set_directive_resource -core Mul "wallis/loop_sum" tmp_pow
set_directive_resource -core Mul "wallis/loop_subData" tmp_pow
set_directive_resource -core Mul "wallis/loop_addData" tmp_pow
