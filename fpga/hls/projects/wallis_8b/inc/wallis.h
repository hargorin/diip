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
typedef ap_uint<10>	apuint10_t;
typedef ap_uint<14>	apuint14_t;
typedef ap_uint<15>	apuint15_t;
typedef ap_uint<16>	apuint16_t;
typedef ap_uint<19>	apuint19_t;
typedef ap_uint<27>	apuint27_t;

typedef ap_int<23>	apint23_t;



#define WIN_LENGTH 	21	// Between 11 and 41 (depends on camera resolution)
#define WIN_SIZE	(WIN_LENGTH * WIN_LENGTH)



typedef ap_axiu<8,1,1,1> AXI_VALUE;		// <TDATA, TUSER, TID, TDEST>
typedef hls::stream<AXI_VALUE> AXI_STREAM;


// ****************************************************************************
// *** Functions ***
// ****************************************************************************

// Top-Function
void wallis(AXI_STREAM &inData, AXI_STREAM &outData, 
			apuint8_t g_Mean, apuint14_t g_Var, ap_ufixed<5,1> contrast,
			ap_ufixed<5,1> brightness);
