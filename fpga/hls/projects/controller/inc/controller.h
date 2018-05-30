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
#define UFT_REG_RX_BASE 2
#define UFT_REG_TX_BASE 3
#define UFT_REG_RX_CTR  4

// ***********************************************
// *** Settings ***
// ***********************************************
#define LINE_SIZE			32
#define N_LINES 			32
//#define LINE_SIZE			128
//#define N_LINES 			128

#define WINDOW_HEIGHT 		21
#define AXI_M_BURST_SIZE	WINDOW_HEIGHT // chosen to neighbourhood size


// From here the input image is stored by the UFT block
#define IN_MEMORY_BASE 		0x00000000
// From here the output image is stored by the controller
#define OUT_MEMORY_BASE 	(IN_MEMORY_BASE+(LINE_SIZE*N_LINES))

#define IN_SIZE 			(LINE_SIZE*N_LINES)
#define IN_LINE_SIZE		(LINE_SIZE*WINDOW_HEIGHT)
#define OUT_SIZE 			((LINE_SIZE-WINDOW_HEIGHT+1)*(N_LINES-WINDOW_HEIGHT+1))
#define OUT_LINE_SIZE		(LINE_SIZE-WINDOW_HEIGHT+1)

#define TOTAL_MEM_SIZE 		(IN_SIZE+OUT_SIZE)



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
