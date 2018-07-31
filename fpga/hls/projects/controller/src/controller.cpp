//
//  controller.cpp
//
//  Created by Noah Huetter on 04/23/18.
//  Copyright © 2018 Noah Huetter. All rights reserved.
//

#include "../inc/controller.h"
#include "ap_utils.h"

void fillBuff(volatile uint8_t *memp, volatile uint8_t *buf,
    uint32_t imgWidth, uint32_t off);

void runOutStream(AXI_STREAM &outData);
void runInStream(AXI_STREAM &inData);


static enum myState {S_INIT, S_IDLE, S_READ, S_STREAM, S_WRITE, S_WAIT_TO_SEND, S_SEND} state = S_IDLE;

// Local ping pong memory for image data
static uint8_t ppBufA[PIN_PONG_BUF_SIZE];
static uint8_t ppBufB[PIN_PONG_BUF_SIZE];
// Pointer to the two buffers
static uint8_t* outPpBuf = ppBufA;
static uint8_t* inPpBuf = ppBufB;
static bool ppBufArdy = false;
static bool ppBufBrdy = false;
static uint32_t bufOff = 0;

static uint8_t out_mem[OUT_BUF_SIZE];

// Exit condition for output streaming
static uint32_t imgWidth = 0;
static uint32_t inLineSize = 0;

// Data for mem to stream
static bool runOut = false;
static bool runOutDone = false;
static int ms_off, ms_pctr, ms_rctr, ms_cctr;

// Data for stream to stream
static bool runIn = false;
static int sm_ctr;

/**
 *
 */
void controller_top(volatile uint8_t *memp, volatile uint32_t *cbus,
     AXI_STREAM &inData,
     AXI_STREAM &outData,
     ap_uint<1> rx_done,
     ap_uint<1> tx_ready,
     ap_uint<4> *outState)
{
#pragma HLS INTERFACE ap_none port=outState
//#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS DATAFLOW

#pragma HLS INTERFACE m_axi depth=16 port=cbus offset=direct bundle=cbus
#pragma HLS INTERFACE m_axi depth=2796 port=memp offset=off bundle=memp
#pragma HLS INTERFACE axis register reverse port=inData
#pragma HLS INTERFACE axis register forward port=outData

#pragma HLS INLINE region


//#pragma HLS pipeline II=1 enable_flush

//    switch(state)
//    {
//        case S_INIT:
//            cbus[UFT_REG_CONTROL] = 0x00000000;
//            state = S_IDLE;
//            break;
//        case S_IDLE:
//            if(rx_done == 1)
//            {
//                state = S_READ;
//                imgWidth = cbus[UFT_REG_IMG_WIDTH];
//                inLineSize = WINDOW_LEN*imgWidth;
//            }
//            break;
//        case S_READ:
//            // Initially fill first pp buf
//            printf("Start filling buff A\n");
//            fillBuff(memp, ppBufA, imgWidth, 0);
//            bufOff = AXI_BURST_SIZE;
//            // Init variables for ping pong buffers
//            ppBufArdy = true;
//            ppBufBrdy = false;
//            outPpBuf = ppBufA;
//            // Init variables for stream
//            state = S_STREAM;
//            runOut = true;
//            runOutDone = false;
//            runIn = true;
//            ms_pctr = 0;
//            ms_rctr = 0;
//            ms_cctr = 0;
//            sm_ctr = 0;
//            break;
//        case S_STREAM:
            /********* Buffer Switching and reloading *********/
        	if (ms_pctr < (inLineSize-PIN_PONG_BUF_SIZE))
        	{
        		if( (outPpBuf == ppBufA)  )
				{
					if(!ppBufBrdy)
					{
						printf("Start filling buff B\n");
						fillBuff(memp, ppBufB, imgWidth, bufOff);
						bufOff += AXI_BURST_SIZE;
						ppBufBrdy = true;
						runOut = true;
					}
				}
        		else
				{
					if(!ppBufArdy)
					{
						printf("Start filling buff A\n");
						fillBuff(memp, ppBufA, imgWidth, bufOff);
						bufOff += AXI_BURST_SIZE;
						ppBufArdy = true;
						runOut = true;
					}
				}
        	}


            /********* OUT *********/
            if(runOut && !runOutDone)
            {
            	runOutStream(outData);
            }
            /********* IN *********/
            if(runIn)
            {
            	runInStream(inData);
            }

            /********* EXIT *********/
            if(runOutDone && !runIn)
            {
                state = S_WRITE;
            }
//            break;
//        case S_WRITE:
//            // store processed data in memory
//            to_mem: memcpy((void*)(&memp[inLineSize]),(const void*)out_mem,(imgWidth-WINDOW_LEN+1)*sizeof(uint8_t));
//        	state = S_WAIT_TO_SEND;
//            break;
//        case S_WAIT_TO_SEND:
//        	// Check whether the UFT core is ready to send data
//            if(tx_ready == 1)
//            {
//                state = S_SEND;
//            }
//            else
//            {
//                state = S_WAIT_TO_SEND;
//            }
//            break;
//        case S_SEND:
//			// Send start address, size and command
//			state = S_IDLE;
//			b_config: {
//			#pragma HLS PROTOCOL floating
//				cbus[UFT_REG_TX_BASE] = inLineSize;
////				ap_wait_n(5);
//				cbus[UFT_REG_TX_SIZE] = imgWidth-WINDOW_LEN+1;
////				ap_wait_n(5);
//				cbus[UFT_REG_CONTROL] = UFT_REG_CONTROL_TX_START;
////				ap_wait_n(5);
//			}
//        	break;
//    }
//    *outState = state;
}

/**
 * @brief Fills the buffer with data from memp
 * @details 
 * 
 * @param memp      Pointer to image in data
 * @param buf       Pointer to buffer
 * @param imgWidth  The input image width
 * @param off       Offset from memory base
 */
void fillBuff(volatile uint8_t *memp, volatile uint8_t *buf,
    uint32_t imgWidth, uint32_t off)
{
#pragma HLS INLINE
    uint32_t i;
    size_t inOff, outOff;

    loop_fillbuff: for(i = 0; i < WINDOW_LEN; i++)
    {
//#pragma HLS PIPELINE
        inOff = off + i*imgWidth;
        outOff = i*AXI_BURST_SIZE;
        memcpy((void*)(&buf[outOff]),(const void*)(&memp[inOff]),AXI_BURST_SIZE*sizeof(uint8_t));
    }
}



void runOutStream(AXI_STREAM &outData)
{
    AXI_VALUE oPxl;

	if(!outData.full())
	{
		// calc memory offset and read data
		oPxl.data = outPpBuf[AXI_BURST_SIZE*(ms_rctr++) + ms_cctr];
		oPxl.last = 0;
		// set TLAST on last byte
		if( (ms_pctr++) == (inLineSize-1)) oPxl.last = 1;
		outData.write(oPxl);
		// increment
		if (ms_rctr == WINDOW_LEN)
		{
			ms_rctr = 0;
			ms_cctr++;
			// If buffer is written out, stop operation
			if(ms_cctr == AXI_BURST_SIZE)
			{
				// restart counters
				ms_rctr = 0;
				ms_cctr = 0;
				// switch buffers here
				if(outPpBuf == ppBufA)
				{
					ppBufArdy = false;
					outPpBuf = ppBufB;
					if(!ppBufBrdy) runOut = false;
				}
				else
				{
					ppBufBrdy = false;
					outPpBuf = ppBufA;
					if(!ppBufArdy) runOut = false;
				}
			}
		}
		// exit condition
		if( ms_pctr == inLineSize ) runOutDone = true;
	}
}

void runInStream(AXI_STREAM &inData)
{
    AXI_VALUE iPxl;

	if(!inData.empty())
	{
		// store
		iPxl = inData.read();
		out_mem[sm_ctr++] = (uint8_t)iPxl.data;
		// Exit condition
		if (iPxl.last) runIn = false;
	}
}
