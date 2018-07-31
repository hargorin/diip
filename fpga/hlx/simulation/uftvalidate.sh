#!/bin/bash

echo "---- Check Rx streams ----"
echo "This validation only works if all tests are executed"
echo "in uft_top_tb"
DIFF="diff -q --report-identical-files --ignore-case --ignore-trailing-space"

# Test 2
F1=axi_rx_stream_res_0.log
F2=uft_data_tcid_0c_nseq_1_payload.txt
$DIFF build/ghdl/$F1 cores/uft_stack_v2_0/bench/$F2
# Test 3
F1=axi_rx_stream_res_1.log
F2=uft_data_tcid_09_nseq_2_payload.txt
$DIFF build/ghdl/$F1 cores/uft_stack_v2_0/bench/$F2
# Test 4
F1=axi_rx_stream_res_2.log
F2=uft_data_tcid_0c_nseq_1_v2_payload.txt
$DIFF build/ghdl/$F1 cores/uft_stack_v2_0/bench/$F2
# Test 5
F1=axi_rx_stream_res_3.log
F2=uft_data_tcid_0c_nseq_1_31bytes_payload.txt
$DIFF build/ghdl/$F1 cores/uft_stack_v2_0/bench/$F2
# Test 6
F1=axi_rx_stream_res_4.log
F2=uft_data_tcid_0c_nseq_1_30bytes_payload.txt
$DIFF build/ghdl/$F1 cores/uft_stack_v2_0/bench/$F2
# Test 7
F1=axi_rx_stream_res_5.log
F2=uft_data_tcid_0c_nseq_1_29bytes_payload.txt
$DIFF build/ghdl/$F1 cores/uft_stack_v2_0/bench/$F2
echo "---- Done ----"
