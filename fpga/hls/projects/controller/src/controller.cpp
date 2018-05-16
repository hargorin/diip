//
//  controller.cpp
//
//  Created by Noah Huetter on 04/23/18.
//  Copyright © 2018 Noah Huetter. All rights reserved.
//

#include "../inc/controller.h"
#include "ap_utils.h"

void resetUFT(volatile uint32_t *uft_ctrl);
bool mem_to_stream(volatile uint8_t *memp, AXI_STREAM &outData);
bool stream_to_mem(volatile uint8_t *memp, AXI_STREAM &inData);

/**
 *
 */
void controller_top(volatile uint8_t *memp, volatile uint32_t *cbus,
     AXI_STREAM &inData,
     AXI_STREAM &outData,
	 ap_uint<1> rx_done)
{
#pragma HLS DATAFLOW
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS INTERFACE m_axi depth=16 port=cbus offset=off
#pragma HLS INTERFACE m_axi depth=1168 port=memp offset=off bundle=memp
#pragma HLS INTERFACE axis register reverse port=inData
#pragma HLS INTERFACE axis register forward port=outData

#pragma HLS INLINE region
#pragma HLS pipeline II=1 enable_flush

    static enum myState {S_INIT, S_IDLE, S_READ, S_STREAM, S_WRITE, S_SEND} state;

    static uint32_t procdRows = 0;

    // Local memory for image data
    static uint8_t in_mem[IN_LINE_SIZE];
    static uint8_t out_mem[OUT_SIZE];

    // Data for mem to stream
    static bool runOut = false;
    static int ms_off, ms_pctr, ms_rctr, ms_cctr;
    AXI_VALUE oPxl;

    // Data for stream to stream
    static bool runIn = false;
    static int sm_ctr;
    AXI_VALUE iPxl;

    // printf("Old state: %d\n", state);
    switch(state)
    {
        case S_INIT:
            cbus[UFT_REG_CONTROL] = 0x00000000;
            state = S_IDLE;
            break;
        case S_IDLE:
//            if((cbus[UFT_REG_RX_CTR]+procdRows) >= WINDOW_HEIGHT)
//            {
//                state = S_READ;
//            }
            if(rx_done == 1)
            {
                state = S_READ;
            }
            break;
        case S_READ:
            from_mem: memcpy((void*)in_mem,(const void*)(&memp[IN_MEMORY_BASE+(procdRows*LINE_SIZE)]),IN_LINE_SIZE*sizeof(uint8_t));
            state = S_STREAM;
            runOut = true;
            runIn = true;
            ms_pctr = 0;
            ms_rctr = 0;
            ms_cctr = 0;
            sm_ctr = 0;
            break;
        case S_STREAM:
            /********* OUT *********/
        	if(runOut)
        	{
        		runOut = mem_to_stream(in_mem, outData);
        	}
            /********* IN *********/
        	if(runIn)
        	{
        		runIn = stream_to_mem(out_mem, inData);
        	}
			/********* EXIT *********/
			state = S_WRITE;
            break;
        case S_WRITE:
            // store processed data in memory
            to_mem: memcpy((void*)(&memp[OUT_MEMORY_BASE+(procdRows*OUT_LINE_SIZE)]),(const void*)out_mem,OUT_LINE_SIZE*sizeof(uint8_t));
            state = S_SEND;
            break;
        case S_SEND:
        	// send processed data
            cbus[UFT_REG_TX_BASE] = OUT_MEMORY_BASE;
            cbus[UFT_REG_CONTROL] = UFT_REG_CONTROL_TX_START;
            state = S_IDLE;
        	break;
    }
    // printf("New state: %d\n", state);
}


/**
 * Resets the UFT stack settings
 */
void resetUFT(volatile uint32_t *uft_ctrl)
{
#pragma HLS INLINE

    static uint32_t uft_init[16];

    reset_copy: memcpy((void*)uft_ctrl, uft_init, UFT_REG_SIZE*UFT_N_REGS);
    uft_ctrl[UFT_REG_RX_BASE] = IN_MEMORY_BASE;
    uft_ctrl[UFT_REG_TX_BASE] = OUT_MEMORY_BASE;
}

/**
 * Copies the data from memp to the output stream in the order that
 * the Wallis filter requires it
 */
bool mem_to_stream(volatile uint8_t *memp, AXI_STREAM &outData)
{
#pragma HLS PIPELINE

    static int ms_off, ms_pctr, ms_rctr, ms_cctr;
    AXI_VALUE oPxl;

	// calc memory offset and read data
	ms_off = LINE_SIZE*ms_rctr + ms_cctr;
	oPxl.data = memp[ms_off];
	oPxl.last = 0;
	// set TLAST on last byte
	if(ms_pctr == (IN_LINE_SIZE-1))
	{
		oPxl.last = 1;
		return false;
	}
	outData.write(oPxl);
	// increment
	ms_rctr++;
	ms_pctr++;
	if(ms_rctr == WINDOW_HEIGHT)
	{
		ms_rctr = 0;
		ms_cctr++;
	}

	return true;
}

/**
 * Stores the data coming from the stream in memp
 */
bool stream_to_mem(volatile uint8_t *memp, AXI_STREAM &inData)
{
#pragma HLS PIPELINE
    static int sm_ctr;
    AXI_VALUE iPxl;

	iPxl = inData.read();
	memp[sm_ctr] = (uint8_t)iPxl.data;
	// Exit condition
	if (iPxl.last)
	{
		return false;
	}
	sm_ctr++;

	return true;
}


