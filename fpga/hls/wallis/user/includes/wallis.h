//
//  wallis.h
//
//  Created by Jan Stocker on 11.04.2018
//  Copyright © 2018 Jan Stocker. All rights reserved.
//

#ifndef _WALLIS_H_
#define _WALLIS_H_
#endif

#include <stdint.h>
#include <math.h>
#include <hls_stream.h>
#include <ap_int.h>
#include <ap_axi_sdata.h>


// ****************************************************************************
// *** Global Variables ***
// ****************************************************************************
typedef ap_uint<8>	apuint8_t;
typedef ap_uint<16>	apuint16_t;


#define WIN_SIZE 	5


typedef ap_axiu<8,1,1,1> AXI_VALUE;		// <TDATA, TUSER, TID, TDEST>
typedef hls::stream<AXI_VALUE> AXI_STREAM;


// ****************************************************************************
// *** Functions ***
// ****************************************************************************

// Top-Function
void wallis(AXI_STREAM &inData, AXI_STREAM &outData, 
			apuint8_t g_Mean, apuint16_t g_Var, float contrast, float brightness);

// Mean
apuint8_t Cal_Mean(uint32_t sum_Pixel, uint16_t length);

// Varinace
apuint16_t Cal_Variance(apuint8_t mean, apuint8_t *pixel, uint16_t length);

// Wallis Filter
apuint8_t Wallis_Filter(apuint8_t *pixel, apuint8_t n_Mean, apuint16_t n_Var, 
						apuint8_t g_Mean, apuint16_t g_Var, float contrast,
						float brightness, uint16_t length);
