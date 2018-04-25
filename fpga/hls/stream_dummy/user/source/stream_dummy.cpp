//
//  stream_dummy.cpp
//
//  Created by Noah Huetter on 04/23/18.
//  Copyright © 2018 Noah Huetter. All rights reserved.
//

#include "../includes/stream_dummy.h"

/**
 *
 */
void stream_dummy_top(AXI_STREAM &inData, AXI_STREAM &outData)
{
#pragma HLS INTERFACE axis register reverse port=inData
#pragma HLS INTERFACE axis register forward port=outData

	int i, col_ctr, row_ctr, off, pixel_ctr, in_ctr;
    int buff[AXI_M_BURST_SIZE];

    AXI_VALUE outPixel;
    AXI_VALUE inPixel;
    AXI_VALUE aval;

    // loop through input data and store in output
    loop_in:for(in_ctr = 0; in_ctr < (LINE_SIZE-WINDOW_HEIGHT+1); in_ctr++)
    {
#pragma HLS PIPELINE
        aval.data = inData.read().data + 2;
        outData.write(aval);
    }
}

