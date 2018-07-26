############################################################
## This file is generated automatically by Vivado HLS.
## Please DO NOT edit it.
## Copyright (C) 1986-2017 Xilinx, Inc. All Rights Reserved.
############################################################
set_directive_interface -mode axis -register -register_mode reverse "ecc" inData
set_directive_interface -mode axis -register -register_mode forward "ecc" outMean
set_directive_interface -mode axis -register -register_mode forward "ecc" outVar
set_directive_interface -mode ap_ctrl_hs "ecc"
set_directive_loop_tripcount -min 1 -max 9 -avg 9 "ecc/loop_while"
