//
//  controller.cpp
//
//  Created by Noah Huetter on 04/23/18.
//  Copyright © 2018 Noah Huetter. All rights reserved.
//

#include "../includes/controller.h"

/**
 *
 */
void controller_top(volatile uint8_t *memp, AXI_STREAM &outData, AXI_STREAM &inData)
{
#pragma HLS INTERFACE ap_ctrl_hs port=return
#pragma HLS INTERFACE axis register reverse port=inData
#pragma HLS INTERFACE axis register forward port=outData
#pragma HLS INTERFACE m_axi depth=1168 port=memp offset=off

	int i, col_ctr, row_ctr, off, pixel_ctr, in_ctr;
    int buff[AXI_M_BURST_SIZE];

    AXI_VALUE outPixel;
    AXI_VALUE inPixel;


    // Loop through every pixel
    col_ctr = 0;
    row_ctr = 0;
    loop_out:for(pixel_ctr = 0; pixel_ctr < (WINDOW_HEIGHT*LINE_SIZE); pixel_ctr++)
    {
#pragma HLS PIPELINE
    	// calculate pixel address
    	off = (IN_MEMORY_BASE + LINE_SIZE*row_ctr + col_ctr);

    	// read one pixel to Stream
    	outPixel.data = memp[off];
        // set TLAST on last byte
    	if(pixel_ctr == (WINDOW_HEIGHT*LINE_SIZE-1))
    	{
    		outPixel.last = 1;
    	}
    	outData.write(outPixel);

    	// increment
    	row_ctr++;
    	if(row_ctr == WINDOW_HEIGHT)
    	{
    		row_ctr = 0;
    		col_ctr++;
    	}
    }

    // loop through input data and store in memory
    in_ctr = 0;
    loop_in:do
    {
    	inPixel = inData.read();
    	// TODO: The following will not work due to read-modify-write
    	// on a 32bit bus with 8bit data
		memp[OUT_MEMORY_BASE+in_ctr] = (uint8_t)inPixel.data;
    	in_ctr++;
    } while (!inPixel.last && (in_ctr < (LINE_SIZE-WINDOW_HEIGHT+1)));

//    loop_in:for(in_ctr = 0; in_ctr < (LINE_SIZE-WINDOW_HEIGHT+1); in_ctr++)
//    {
//
//    }
}


//memcpy creates a burst access to memory
//multiple calls of memcpy cannot be pipelined and will be scheduled sequentially
//memcpy requires a local buffer to store the results of the memory transaction
//	memcpy(buff,(const int*)a[IN_MEMORY_BASE],AXI_M_BURST_SIZE*sizeof(int));


//for(i=0; i < 50; i++){
//	buff[i] = buff[i] + 100;
//}
//
//memcpy((int *)a,buff,50*sizeof(int));


