#################################################
#
#  sobel_tb.tcl
#
#  Created by Jan Stocker on 30/11/17.
#  Copyright © 2017 Jan Stocker. All rights reserved.
#
#################################################

#################################################
# Usage
# > vivado -mode batch -source sobel_tb.tcl -tclargs infile outfile width height burst_length
# Note: Bitstream needs to be downloaded and running first
#################################################


#################################################
# file2bram2file
#   - read data from file and send it to BRAM
#	- read data from BRAM and save it to file
#   data in file are binary
#
#	addr:  		addr of the first BRAM
#	img_width:	image width in pixels (cols)
#	img_height: image height in pixel (rows)
#	in_fp:		input file name
#	out_fp:		output file name
proc file2bram2file {addr in_fp out_fp img_width img_height burst_length} {
	puts "----------------------------------------"
	puts "Start to Write Data From File to BRAM"
	puts "----------------------------------------"

	# open and read file
	puts "Input File: $in_fp"
	set fp [open $in_fp r]

	fconfigure $fp -translation binary
	set inBinData [read $fp]
	close $fp


	set wr_nr 0	

	for {set itr 0} {$itr < $img_height} {incr itr} {
		puts $itr

		#remove previously created txn if exist
		if {[llength [get_hw_axi_txns wr_txn_* -quiet]] > 0} {
			delete_hw_axi_txn [get_hw_axi_txns wr_txn_*]
			delete_hw_axi_txn [get_hw_axi_txns r_pixel_res]
		}

		set wr_nr $itr

		# input BRAM 1
		set addr 0xc0000000
		binary scan [string range $inBinData [expr {$wr_nr * $img_width}] [expr {$wr_nr * $img_width + $img_width - 1}]] H* hexData
			#set addr_string [format "0x%x" [expr $addr + 0 * 256 * 4]]
		create_hw_axi_txn wr_txn_0 [get_hw_axis] -address $addr -data $hexData -len $burst_length -type write
		incr wr_nr

		# input BRAM 2
		set addr 0xc2000000
		binary scan [string range $inBinData [expr {$wr_nr * $img_width}] [expr {$wr_nr * $img_width + $img_width - 1}]] H* hexData
			#set addr_string [format "0x%x" [expr $addr + 0 * 256 * 4]]
		create_hw_axi_txn wr_txn_1 [get_hw_axis] -address $addr -data $hexData -len $burst_length -type write
		incr wr_nr

		# input BRAM 3
		set addr 0xc4000000
		binary scan [string range $inBinData [expr {$wr_nr * $img_width}] [expr {$wr_nr * $img_width + $img_width - 1}]] H* hexData
			#set addr_string [format "0x%x" [expr $addr + 0 * 256 * 4]]
		create_hw_axi_txn wr_txn_2 [get_hw_axis] -address $addr -data $hexData -len $burst_length -type write
		incr wr_nr

		# output BRAM 4
	  	set addr 0xc6000000
	  	create_hw_axi_txn r_pixel_res [get_hw_axis hw_axi_1] -address $addr -len $burst_length -type read


	  	# run
		run_hw_axi wr_txn_0
		run_hw_axi wr_txn_1
		run_hw_axi wr_txn_2

		start_ip 0x40000000

		run_hw_axi r_pixel_res


		# save data from bram in temp variable
		set data_BRAM4 0
		set data_BRAM4 [report_hw_axi_txn -t x4 -w 4 [get_hw_axi_txns r_pixel_res]]

		set arr_cnt 0
	    for {set i [expr {$burst_length*2-1}]} { $i > 0 } { incr i -2 } {
	      if {$arr_cnt == 0} {
	      	lappend temp_list [string range [lindex $data_BRAM4 $i ] 4 8]
	      } else {
	      	lappend temp_list [lindex $data_BRAM4 $i ]
	      }
	      
	      set arr_cnt 1
	    }
	    set temp_data [join $temp_list ""]
	}


    # save data in file
	set fp [open $out_fp w]
	fconfigure $fp -translation binary

	puts $fp [binary format H* $temp_data]

    close $fp
}


#############################################
# start_ip
#   addr: start read address
proc start_ip {addr} {
  
  # remove previously created txn if exist
  if {[llength [get_hw_axi_txns w_st* -quiet]] > 0} {
    delete_hw_axi_txn [get_hw_axi_txns w_st*]
  }

  create_hw_axi_txn w_start [get_hw_axis hw_axi_1] -address $addr -data {00000001} -len 1 -type write
  create_hw_axi_txn w_stop [get_hw_axis hw_axi_1] -address $addr -data {00000000} -len 1 -type write 

  run_hw_axi w_start
  run_hw_axi w_stop
}


#############################################
# connect_xc7a200t
proc connect_xc7a200t {} {
  connect_hw_server
  open_hw_target

  set_property PROGRAM.FILE {build/sobel.bit} [get_hw_devices xc7a200t_0]
  set_property PROBES.FILE {build/sobel.ltx} [get_hw_devices xc7a200t_0]
  set_property FULL_PROBES.FILE {build/sobel.ltx} [get_hw_devices xc7a200t_0]
  current_hw_device [get_hw_devices xc7a200t_0]
  refresh_hw_device [lindex [get_hw_devices xc7a200t_0] 0]
}



# --------
#   main
# --------
set infile [lindex $argv 0]
set outfile [lindex $argv 1]
set width [lindex $argv 2]
set height [lindex $argv 3]
set burst_length [lindex $argv 4]

# Connect hw server
# This part of tcl commands are board related.
# They can be copied from Vivado Tcl Console after connecting to FPGA successfully
open_hw
connect_xc7a200t

file2bram2file 0x00000000 $infile $outfile $width $height $burst_length

close_hw
