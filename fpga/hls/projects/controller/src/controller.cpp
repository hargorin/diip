//
//  controller.cpp
//
//  Created by Noah Huetter on 04/23/18.
//  Copyright © 2018 Noah Huetter. All rights reserved.
//

#include "../inc/controller.h"
#include "ap_utils.h"

void resetUFT(volatile uint32_t *uft_ctrl);
void mem_to_stream(volatile uint8_t *memp, AXI_STREAM &outData);
void stream_to_mem(volatile uint8_t *memp, AXI_STREAM &inData);

/**
 *
 */
void controller_top(volatile uint8_t *memp, volatile uint32_t *cbus,
     AXI_STREAM &inData,
     AXI_STREAM &outData)
{

#pragma HLS INTERFACE m_axi depth=16 port=cbus
#pragma HLS INTERFACE m_axi depth=1168 port=memp offset=off bundle=memp
#pragma HLS INTERFACE axis register reverse port=inData
#pragma HLS INTERFACE axis register forward port=outData

#pragma HLS INLINE region
#pragma HLS pipeline II=1 enable_flush

    static enum myState {S_INIT, S_IDLE, S_READ, S_STREAM, S_WRITE} state;

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
            cbus[0] = 0x00000000;
            state = S_IDLE;
            break;
        case S_IDLE:
            if((cbus[UFT_REG_RX_CTR]+procdRows) >= WINDOW_HEIGHT)
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
                // calc memory offset and read data
                ms_off = LINE_SIZE*ms_rctr + ms_cctr;
                oPxl.data = in_mem[ms_off];
                oPxl.last = 0;
                // set TLAST on last byte
                if(ms_pctr == (IN_LINE_SIZE-1))
                {
                    oPxl.last = 1;
                    runOut = false;
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
            }
            /********* IN *********/
            if(runIn)
            {
                iPxl = inData.read();
                out_mem[sm_ctr] = (uint8_t)iPxl.data;
                // Exit condition
                if (iPxl.last)
                {
                    runIn = false;
                }
                sm_ctr++;
            }
            /********* EXIT *********/
            if(!runOut && !runIn)
            {
                state = S_WRITE;
            }
            break;
        case S_WRITE:
            // store processed data in memory
            to_mem: memcpy((void*)(&memp[OUT_MEMORY_BASE+(procdRows*OUT_LINE_SIZE)]),(const void*)out_mem,OUT_LINE_SIZE*sizeof(uint8_t));
            state = S_IDLE;
            break;
    }
    // printf("New state: %d\n", state);
}

// void controller_top(volatile uint8_t *memp, 
//     volatile uint32_t *uft_ctrl,
//     AXI_STREAM &outData, 
//     AXI_STREAM &inData,
//     apuint32_t *uft_tx_memory_address,
//     ap_uint<1> *uft_tx_start)
// {
// #pragma HLS DATAFLOW
// #pragma HLS INTERFACE ap_ctrl_hs port=return
// //#pragma HLS INTERFACE ap_ctrl_hs port=return
// #pragma HLS INTERFACE axis register reverse port=inData
// #pragma HLS INTERFACE axis register forward port=outData
// #pragma HLS INTERFACE m_axi depth=16 port=uft_ctrl offset=off bundle=uft_ctrl
// #pragma HLS INTERFACE m_axi depth=1168 port=memp offset=off bundle=memp
// #pragma HLS INTERFACE ap_ovld register forward port=uft_tx_memory_address
// #pragma HLS INTERFACE ap_none port=uft_tx_start

//     // State machine (from XAPP1209)
//     static enum dState {S_INIT = 0, S_IDLE, S_READ, S_STREAM, S_WRITE} enState = S_INIT;
//     // stores the number of lines processed
//     static uint32_t procdRows = 0;


//     static uint8_t in_mem[IN_LINE_SIZE];
//     static uint8_t out_mem[OUT_SIZE];


//     //**********************************************************************
//     // Run state machine
//     //**********************************************************************
//     switch(enState)
//     {
//         case S_INIT:
//             // Reset UFT registers to default
//             resetUFT(uft_ctrl);
//             enState = S_IDLE;
//             break;
//         case S_IDLE:
//             // Check whether enough rows are received
//             if((uft_ctrl[UFT_REG_RX_CTR]+procdRows) >= WINDOW_HEIGHT)
//             {
//                 enState = S_READ;
//             }
//             break;
//         case S_READ:
//             // store necessary data in local memory
//             from_mem: memcpy((void*)in_mem,(const void*)(&memp[IN_MEMORY_BASE+(procdRows*LINE_SIZE)]),IN_LINE_SIZE*sizeof(uint8_t));
//             enState = S_STREAM;
//             break;
//         case S_STREAM:
//             // stream data through filter
//             mem_to_stream(in_mem, outData);
//             stream_to_mem(out_mem, inData);
//             enState = S_WRITE;
//             break;
//         case S_WRITE:
//             // store processed data in memory
//             to_mem: memcpy((void*)(&memp[OUT_MEMORY_BASE+(procdRows*OUT_LINE_SIZE)]),(const void*)out_mem,OUT_LINE_SIZE*sizeof(uint8_t));
//             enState = S_IDLE;
//             break;
//     }

// //    // init
// //    *uft_tx_start = 0;
// //
// //    // copy input data
// //    mem_read: {
// //        #pragma HLS protocol fixed
// //        memcpy((void*)in_mem,(const void*)(&memp[IN_MEMORY_BASE]),IN_LINE_SIZE*sizeof(uint8_t));
// //    }
// //
// //    operation: {
// //    }
// //
// //    // copy output data
// //    mem_write: {
// //        #pragma HLS protocol fixed
// //        memcpy((void*)(&memp[OUT_MEMORY_BASE]),(const void*)out_mem,OUT_LINE_SIZE*sizeof(uint8_t));
// //    }
// //
// //    // start UFT transmission
// //    signal_uft: {
// ////        #pragma HLS protocol fixed
// //        *uft_tx_memory_address = OUT_MEMORY_BASE;
// //        *uft_tx_start = 1;
// //        ap_wait_n(1);
// //        *uft_tx_start = 0;
// //    }

// }

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
void mem_to_stream(volatile uint8_t *memp, AXI_STREAM &outData)
{
#pragma HLS INLINE

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

/**
 * Stores the data coming from the stream in memp
 */
void stream_to_mem(volatile uint8_t *memp, AXI_STREAM &inData)
{
#pragma HLS INLINE
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


