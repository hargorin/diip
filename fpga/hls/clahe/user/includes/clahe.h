//
//  clahe.h
//
//  Created by Jan Stocker on 11.04.2018
//  Copyright © 2018 Jan Stocker. All rights reserved.
//

#ifndef _CLAHE_H_
#define _CLAHE_H_
#endif

#include <stdint.h>
#include <hls_stream.h>
#include <ap_int.h>
#include <ap_axi_sdata.h>


// ****************************************************************************
// *** Global Variables ***
// ****************************************************************************
typedef ap_uint<8>	uint8;
typedef ap_uint<16>	uint16;


#define WIN_SIZE 	4
#define BLOCK_SIZE 	64
#define NUM_BINS 	256

typedef uint8 Pixel_t[BLOCK_SIZE * BLOCK_SIZE];
typedef uint16 Hist_t[NUM_BINS];
typedef uint8 Cdf_t[NUM_BINS];

typedef struct Block {
	Pixel_t pixel;
	Hist_t hist;
	Cdf_t cdf;
} Block_t;

typedef ap_axiu<8,1,1,1> AXI_VALUE;		// <TDATA, TUSER, TID, TDEST>
typedef hls::stream<AXI_VALUE> AXI_STREAM;


// ****************************************************************************
// *** Functions ***
// ****************************************************************************

// Top-Function
void clahe(AXI_STREAM &inData0, AXI_STREAM &inData1, AXI_STREAM &inData2, AXI_STREAM &inData3,
			AXI_STREAM &outData0, AXI_STREAM &outData1, AXI_STREAM &outData2, AXI_STREAM &outData3);
