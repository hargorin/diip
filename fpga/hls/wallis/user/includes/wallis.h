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
#include <hls_stream.h>
#include <ap_int.h>
#include <ap_fixed.h>
#include <ap_axi_sdata.h>


// ****************************************************************************
// *** Global Variables ***
// ****************************************************************************
typedef ap_uint<8>	apuint8_t;
typedef ap_uint<11>	apuint11_t;
typedef ap_uint<14>	apuint14_t;
typedef ap_uint<16>	apuint16_t;
typedef ap_uint<24>	apuint24_t;
typedef ap_uint<32>	apuint32_t;
typedef ap_uint<35>	apuint35_t;
typedef ap_uint<40>	apuint40_t;

typedef ap_int<48>	apint48_t;

// !!! If the WIN_SIZE changes - the data types must change too !!!
#define WIN_SIZE 	21	// Between 11 and 41 (depends on camera resolution)
#define LENGTH 		(WIN_SIZE * WIN_SIZE)


typedef ap_axiu<8,1,1,1> AXI_VALUE;		// <TDATA, TUSER, TID, TDEST>
typedef hls::stream<AXI_VALUE> AXI_STREAM;


// ****************************************************************************
// *** Functions ***
// ****************************************************************************

// Top-Function
void wallis(AXI_STREAM &inData, AXI_STREAM &outData, 
			apuint8_t g_Mean, apuint16_t g_Var, ap_fixed<7,1> contrast,
			ap_fixed<7,1> brightness, apuint16_t g_Width);

// Mean
apuint8_t Cal_Mean(apuint14_t sum_Pixel);

// Varinace
apuint35_t Cal_Variance(apuint8_t mean, apuint8_t *pixel);

// Wallis Filter
apuint8_t Wallis_Filter(apuint8_t v_pixel, apuint8_t n_Mean, apuint35_t n_Var,
						apuint8_t g_Mean, apuint16_t g_Var,
						float fContrast, float fBrightness);
