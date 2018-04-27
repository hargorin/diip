//
//  stream_dummy.cpp
//
//  Created by Noah Huetter on 04/23/18.
//  Copyright © 2018 Noah Huetter. All rights reserved.
//

#include "../inc/stream_dummy.h"

/**
 *
 */
void stream_dummy_top(AXI_STREAM &inData, AXI_STREAM &outData)
{
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS INTERFACE axis register reverse port=inData
#pragma HLS INTERFACE axis register forward port=outData

	int i, col_ctr, row_ctr, off, pixel_ctr, in_ctr;
    int buff[AXI_M_BURST_SIZE];

    AXI_VALUE outPixel;
    AXI_VALUE inPixel;
    AXI_VALUE aval;

    // read initial block of N*N pixels
    loop_in_wait:for(pixel_ctr = 0; pixel_ctr < (WINDOW_HEIGHT*WINDOW_HEIGHT); pixel_ctr++)
    {
        inPixel = inData.read();
    }
    // write one
    // copy data
    outPixel = inPixel;
    // increment data
    outPixel.data = inPixel.data + 2;
    outData.write(outPixel);
    

    // loop through input data and store ever WINDOW_HEIGHT'th in output
    pixel_ctr = 0;
    loop_in:do
    {
#pragma HLS PIPELINE
    	// read byte
    	inPixel = inData.read();
        pixel_ctr++;
        if(pixel_ctr == WINDOW_HEIGHT)
        {
            pixel_ctr = 0;
            // copy data
            outPixel = inPixel;
            // increment data
            outPixel.data = inPixel.data + 2;
            outData.write(outPixel);
        }
    } while(!inPixel.last);

//    loop_in:for(in_ctr = 0; in_ctr < (LINE_SIZE-WINDOW_HEIGHT+1); in_ctr++)
//    {
//#pragma HLS PIPELINE
//        c.data + 2;
//        outData.write(aval);
//    }
}

