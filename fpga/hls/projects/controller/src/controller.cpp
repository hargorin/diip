//
//  controller.cpp
//
//  Created by Noah Huetter on 04/23/18.
//  Copyright © 2018 Noah Huetter. All rights reserved.
//

#include "../inc/controller.h"
#include "ap_utils.h"

void mem_to_stream(volatile uint8_t *memp, AXI_STREAM &outData);
void stream_to_mem(volatile uint8_t *memp, AXI_STREAM &inData);

/**
 *
 */
void controller_top(volatile uint8_t *memp, 
	volatile apuint32_t *uft_ctrl,
    AXI_STREAM &outData, 
    AXI_STREAM &inData,
    apuint32_t *uft_tx_memory_address,
    ap_uint<1> *uft_tx_start)
{
#pragma HLS DATAFLOW
#pragma HLS INTERFACE ap_ctrl_hs port=return
#pragma HLS INTERFACE axis register reverse port=inData
#pragma HLS INTERFACE axis register forward port=outData
#pragma HLS INTERFACE m_axi depth=16 port=uft_ctrl offset=off bundle=uft_ctrl
#pragma HLS INTERFACE m_axi depth=1168 port=memp offset=off bundle=memp
#pragma HLS INTERFACE ap_ovld register forward port=uft_tx_memory_address
#pragma HLS INTERFACE ap_none port=uft_tx_start

	static uint8_t in_mem[IN_LINE_SIZE];
	static uint8_t out_mem[OUT_SIZE];

	// axi lite
	uft_ctrl[0] = 0x1;
	uft_ctrl[1] = 0x400;
	uft_ctrl[2] = 0x1;
	uft_ctrl[3] = 0x400;
	uft_ctrl[4] = 0x1;
	uft_ctrl[5] = 0x400;
	uft_ctrl[6] = 0x1;
	uft_ctrl[7] = 0x400;
	uft_ctrl[8] = 0x1;
	uft_ctrl[9] = 0x400;
	uft_ctrl[10] = 0x1;
	uft_ctrl[11] = 0x400;
	uft_ctrl[12] = 0x1;
	uft_ctrl[13] = 0x400;
	uft_ctrl[14] = 0x1;
	uft_ctrl[15] = 0x400;
	// init
	*uft_tx_start = 0;

	// copy input data
	mem_read: {
		#pragma HLS protocol fixed
		memcpy((void*)in_mem,(const void*)(&memp[IN_MEMORY_BASE]),IN_LINE_SIZE*sizeof(uint8_t));
	}

	operation: {
		mem_to_stream(in_mem, outData);
		stream_to_mem(out_mem, inData);
	}

	// copy output data
	mem_write: {
		#pragma HLS protocol fixed
		memcpy((void*)(&memp[OUT_MEMORY_BASE]),(const void*)out_mem,OUT_LINE_SIZE*sizeof(uint8_t));
	}

    // start UFT transmission
    signal_uft: {
//		#pragma HLS protocol fixed
		*uft_tx_memory_address = OUT_MEMORY_BASE;
		*uft_tx_start = 1;
		ap_wait_n(1);
		*uft_tx_start = 0;
    }

}


void mem_to_stream(volatile uint8_t *memp, AXI_STREAM &outData)
{

	int col_ctr, row_ctr, off, pixel_ctr;
    int buff[AXI_M_BURST_SIZE];

    AXI_VALUE outPixel;

    // Loop through every pixel
    col_ctr = 0;
    row_ctr = 0;
    loop_out:for(pixel_ctr = 0; pixel_ctr < IN_LINE_SIZE; pixel_ctr++)
    {
#pragma HLS PIPELINE
    	// calculate pixel address
    	off = LINE_SIZE*row_ctr + col_ctr;

    	// read one pixel to Stream
    	outPixel.data = memp[off];
        // set TLAST on last byte
    	if(pixel_ctr == (IN_LINE_SIZE-1))
    	{
    		outPixel.last = 1;
    	}
        else
        {
            outPixel.last = 0;
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

}
void stream_to_mem(volatile uint8_t *memp, AXI_STREAM &inData)
{
	int in_ctr;

    AXI_VALUE inPixel;

    // loop through input data and store in memory
    in_ctr = 0;
    loop_in:for(in_ctr = 0; (in_ctr < (OUT_LINE_SIZE)); in_ctr++)
//    loop_in:do
    {
#pragma HLS PIPELINE
    	inPixel = inData.read();
    	// TODO: The following will not work due to read-modify-write
    	// on a 32bit bus with 8bit data
		memp[in_ctr] = (uint8_t)inPixel.data;
		if (inPixel.last)
		{
			break;
		}
    }
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


