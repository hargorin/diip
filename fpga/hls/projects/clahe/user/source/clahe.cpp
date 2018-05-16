//
//  clahe.cpp
//
//  Created by Jan Stocker on 11.04.2018
//  Copyright © 2018 Jan Stocker. All rights reserved.
//

#include "../includes/clahe.h"


void clahe(AXI_STREAM &inData0, AXI_STREAM &inData1, AXI_STREAM &inData2, AXI_STREAM &inData3,
			AXI_STREAM &outData0, AXI_STREAM &outData1, AXI_STREAM &outData2, AXI_STREAM &outData3) {
	
	#pragma HLS INTERFACE axis port=inData0
	#pragma HLS INTERFACE axis port=inData1
	#pragma HLS INTERFACE axis port=inData2
	#pragma HLS INTERFACE axis port=inData3
	#pragma HLS INTERFACE axis port=outData0
	#pragma HLS INTERFACE axis port=outData1
	#pragma HLS INTERFACE axis port=outData2
	#pragma HLS INTERFACE axis port=outData3

	// ************************************************************************
	// Variables
	AXI_STREAM* inData[4] = {
		inData0, inData1, inData2, inData3
	};

	AXI_STREAM* outData[4] = {
		outData0, outData1, outData2, outData3
	};

	AXI_VALUE intensity[4];
	AXI_VALUE outPixel[4];
	Block_t block[WIN_SIZE * WIN_SIZE];
	Cdf_t cdf_store[WIN_SIZE] = {}; // CDF Storage for the next iteration


	// ************************************************************************
	// Calculate Histogram
	for(uint16_t i = 0; i < (BLOCK_SIZE * BLOCK_SIZE); i++) {
		//#pragma HLS PIPELINE
		for(uint8_t k = 0; k < WIN_SIZE; k++) {
			intensity[k] = &inData[k].read();
			block[k].pixel[i] = intensity[k].data;
			block[k].hist[intensity[k].data] += 1;
		}
	}






	for (uint16_t i = 0; i < NUM_BINS; i++) {
		//#pragma HLS PIPELINE
		for(uint8_t k = 0; k < WIN_SIZE; k++) {
			outPixel[k].data = block[k].hist[i];
			&outData[k].write(outPixel[k]);
		}
	}
}



