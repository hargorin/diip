# @Author: Noah
# @Date:   2018-04-26 08:43:57
# @Last Modified by:   Noah
# @Last Modified time: 2018-04-26 14:23:15

#################################################
# dump
#   - dump memory region to file
#
#   fname:      file name
#   addr:       base addr of RAM
#   size:       number of bytes to read
proc dump {fname addr size} {
    # Settings
    set hw_axi [get_hw_axis]
    # Junks of data per transaction, nbytes = transaction_size*4
    set transaction_size 32

    # Loop over all transactions
    set n_transactions [expr {ceil($size/(4*$transaction_size))}]
    if {[expr {$size%(4*$transaction_size)}] >= 1} {
        set n_transactions [expr {$n_transactions+1}]
    }
    puts [format "Initiating %.0f transactions" $n_transactions]
    for {set i 0} {$i < $n_transactions} {incr i} {
        # Status
        puts -nonewline [format "\rProgress: %3.0f%% " [expr {$i * 100 / $n_transactions}]]
        # calculate current offset
        set addr_off [format %x [expr {[scan $addr %x] + $i*$transaction_size*4}]]
        # create read transaction
        create_hw_axi_txn rd_t $hw_axi -force -address $addr_off -type read -len $transaction_size
        # Run transaction
        run_hw_axi rd_t
        # Store result
        set res [report_hw_axi_txn -t x4 -w 4 [get_hw_axi_txns rd_t]]
        # puts $res
        # remove transaction
        delete_hw_axi_txn [get_hw_axi_txns rd_t]
        # Store results
        set res_lines [split $res "\n\r "]
        set listwithoutnulls [lsearch -all -inline -not -exact $res_lines {} ]

        set j 0
        foreach entry $listwithoutnulls {
            # Every second is value, others are address
            if {$j == 0} {
                set j 1
            } else {
                lappend temp_list $entry
                set j 0
            }            
        }
    }
    puts "\r100% Done     "
    # Only write requested bytes to file
    set temp_data [join $temp_list ""]
    set temp_data [string range $temp_data 0 [expr 2*$size-1]]

    # endian fix
    set endian_tmp {}
    for {set i 0} {$i < [string length $temp_data]} {incr i 8} {
        append endian_tmp [string range $temp_data [expr {$i + 6}] [expr {$i+7}]]
        append endian_tmp [string range $temp_data [expr {$i + 4}] [expr {$i+5}]]
        append endian_tmp [string range $temp_data [expr {$i + 2}] [expr {$i+3}]]
        append endian_tmp [string range $temp_data [expr {$i + 0}] [expr {$i+1}]]
    }
    set temp_data $endian_tmp


    # save data in file
    set fp [open $fname w]
    fconfigure $fp -translation binary
    puts -nonewline $fp [binary format H* $temp_data]
    close $fp
}

#################################################
# writeto
#   - write memory region from file
#
#   fname:      source file name
#   addr:       base addr of RAM
proc writeto {fname addr} {
    # Settings
    set hw_axi [get_hw_axis]
    # Junks of data per transaction
    set transaction_size 16

    # open input file and read
    set fp [open $fname r]
    fconfigure $fp -translation binary
    set inBinData [read $fp]
    close $fp
    # Append zeros to round to div 4 bytes
    # lappend inBinData "\0\0\0\0"
    set nbytes [file size $fname]

    # Loop over all transactions
    set n_transactions [expr {ceil($nbytes/$transaction_size)}]
    if {[expr {$nbytes%$transaction_size}] >= 1} {
        set n_transactions [expr {$n_transactions+1}]
    }
    puts [format "Initiating %.0f transactions" $n_transactions]
    set wr_nr 0 
    for {set i 0} {$i < $n_transactions} {incr i} {
        # Status
        puts -nonewline [format "\rProgress: %3.0f%% " [expr {$i * 100 / $n_transactions}]]
        # calculate current offset
        set addr_off [format %x [expr {[scan $addr %x] + $i*$transaction_size}]]
        # create read transaction
        set data_r [string range $inBinData [expr {$i * $transaction_size}] [expr {$i * $transaction_size + $transaction_size-1}]]
        set data_r2 {}
        for {set j [expr $transaction_size-4]} {$j >= 0} {incr j -4} {
            # for {set k 0} {$k < 4} {incr k} {
                append data_r2 [string reverse [string range $data_r $j [expr {$j+3}]]]
            # }
        }   
        binary scan $data_r2 H* hexData
        incr wr_nr
        create_hw_axi_txn wr_t $hw_axi -force -address $addr_off -data $hexData -type write -len [expr {$transaction_size/4}]
        # Run transaction
        run_hw_axi wr_t
        # remove transaction
        delete_hw_axi_txn [get_hw_axi_txns wr_t]
    }
    puts "\r100% Done     "
}