############################################################
## This file is generated automatically by Vivado HLS.
## Please DO NOT edit it.
## Copyright (C) 1986-2017 Xilinx, Inc. All Rights Reserved.
############################################################
set_directive_interface -mode axis -register -register_mode reverse "wallis" inData
set_directive_interface -mode axis -register -register_mode forward "wallis" outData
set_directive_interface -mode s_axilite -bundle SCALAR_BUS "wallis" g_Mean
set_directive_interface -mode s_axilite -bundle SCALAR_BUS "wallis" g_Var
set_directive_interface -mode s_axilite -bundle SCALAR_BUS "wallis" contrast
set_directive_interface -mode s_axilite -bundle SCALAR_BUS "wallis" brightness
set_directive_interface -mode s_axilite -bundle SCALAR_BUS "wallis" g_Width
set_directive_interface -mode ap_ctrl_hs "wallis"
set_directive_inline "Cal_Mean"
set_directive_inline "Cal_Variance"
set_directive_inline "Wallis_Filter"
set_directive_unroll "Cal_Mean"
set_directive_array_reshape -type cyclic -factor 21 -dim 1 "wallis" pixel
set_directive_pipeline -II 21 "wallis/loop_rdata"
set_directive_pipeline "Cal_Variance/loop_variance"
set_directive_dependence -variable n_Mean -type inter -direction RAW -dependent true "wallis"
set_directive_dependence -variable n_Var -type inter -direction RAW -dependent true "wallis"
set_directive_resource -core MulnS "Cal_Variance" tmp_Pow
set_directive_array_reshape -type cyclic -factor 21 -dim 1 "wallis" tmp_Pixel
set_directive_pipeline "wallis/loop_data"
set_directive_pipeline "wallis/loop_strData"
set_directive_pipeline "wallis/loop_addData"
set_directive_pipeline "wallis/loop_setData"
