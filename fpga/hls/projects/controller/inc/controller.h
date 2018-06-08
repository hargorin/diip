//
//  controller.h
//
//  Created by Noah Huetter on 04/23/18.
//  Copyright © 2018 Noah Huetter. All rights reserved.
//

#ifndef CONTROLLER_H_
#define CONTROLLER_H_
#endif

#include <iostream>
#include <stdio.h>
#include <string.h>

#include <stdint.h>
#include <hls_stream.h>
#include <ap_int.h>
#include <ap_axi_sdata.h>

using namespace std;

// ***********************************************
// *** Global Variables ***
// ***********************************************


// ***********************************************
// UFT Settings
// ***********************************************
#define UFT_REG_SIZE 		 4 // 4 bytes per register
#define UFT_N_REGS 			16 // total of 16 registers

// Register MAP
#define UFT_REG_STATUS  0

#define UFT_REG_CONTROL 1
#define UFT_REG_CONTROL_TX_START 0x00000001

#define UFT_REG_RX_BASE 2
#define UFT_REG_TX_BASE 3
#define UFT_REG_RX_CTR  4
#define UFT_REG_TX_SIZE 5
#define UFT_REG_IMG_WIDTH  8

// ***********************************************
// *** memory layout ***
// ***********************************************
/**
 * Define the window size of the wallis filter algorithm
 */
#define WINDOW_LEN 		21

/**
 * Number of bytes to read in one axi master access
 * This also defines the ping pong buffer size
 */
#define AXI_BURST_SIZE 		32

/**
 * Define the output buffer size. This could later be obsolete
 * if the data is forwarded as stream to the communication block
 * 
 * The imgWidth must not be greater than OUT_SIZE
 */
#define OUT_BUF_SIZE 			18000

/**
 * @brief Ping Pong buffer size
 * @details Choosen to be a multiple of window size. The
 * multiple is the burst transaction size that is done 
 * for axi memp read
 */
#define PIN_PONG_BUF_SIZE 	(WINDOW_LEN*AXI_BURST_SIZE)

/**
 * Where the line data is stored
 */
#define IN_MEMORY_BASE 			0x00000000
/**
 * Where output data is stored
 */
// #ifdef __SYNTHESIS__
// #define OUT_MEMORY_BASE 		0x10000000
// #else
#define IMG_WIDTH 128
#define OUT_MEMORY_BASE 	    (IMG_WIDTH*WINDOW_LEN)
// #endif


// ***********************************************
// *** Types ***
// ***********************************************

typedef ap_uint<8>	apuint8_t;
typedef ap_uint<14>	apuint14_t;
typedef ap_uint<16>	apuint16_t;
typedef ap_uint<32>	apuint32_t;
typedef ap_uint<35>	apuint35_t;
typedef ap_uint<40>	apuint40_t;

typedef ap_axiu<8,1,1,1> AXI_VALUE;		// <TDATA, TUSER, TID, TDEST>

typedef hls::stream<AXI_VALUE> AXI_STREAM;

// ***********************************************
// *** Functions ***
// ***********************************************
// void controller_top(volatile uint8_t *memp,
// 	volatile uint32_t *uft_ctrl,
//     AXI_STREAM &outData,
//     AXI_STREAM &inData,
//     apuint32_t *uft_tx_memory_address,
//     ap_uint<1> *uft_tx_start);

void controller_top(volatile uint8_t *memp, volatile uint32_t *cbus,
     AXI_STREAM &inData,
     AXI_STREAM &outData,
     ap_uint<1> rx_done);
