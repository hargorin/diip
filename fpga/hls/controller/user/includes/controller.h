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
// *** Settings ***
// ***********************************************
#define LINE_SIZE			32
#define N_LINES 			32

#define WINDOW_HEIGHT 		21
#define AXI_M_BURST_SIZE	WINDOW_HEIGHT // chosen to neighbourhood size


// From here the input image is stored by the UFT block
#define IN_MEMORY_BASE 		0x00000000
// From here the output image is stored by the controller
#define OUT_MEMORY_BASE 	(IN_MEMORY_BASE+(LINE_SIZE*N_LINES))

#define IN_SIZE 			(LINE_SIZE*N_LINES)
#define OUT_SIZE 			((LINE_SIZE-WINDOW_HEIGHT+1)*(N_LINES-WINDOW_HEIGHT+1))

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

void controller_top(volatile int *memp, AXI_STREAM &outData, AXI_STREAM &inData);
