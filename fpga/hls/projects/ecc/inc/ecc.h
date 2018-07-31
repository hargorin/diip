//
//  wallis.h
//
//  Created by Jan Stocker on 11.04.2018
//  Copyright © 2018 Jan Stocker. All rights reserved.
//

#ifndef _ECC_H_
#define _ECC_H_
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
typedef ap_uint<11>	apuint11_t;
typedef ap_uint<12>	apuint12_t;
typedef ap_uint<14>	apuint14_t;
typedef ap_uint<16>	apuint16_t;
typedef ap_uint<17>	apuint17_t;
typedef ap_uint<18> apuint18_t;
typedef ap_uint<19>	apuint19_t;
typedef ap_uint<29>	apuint29_t;

typedef ap_int<9>	apint9_t;


#define WIN_LENGTH 	21
#define WIN_SIZE	(WIN_LENGTH * WIN_LENGTH)


typedef ap_axiu<8,1,1,1> AXI_VALUE_8;		// <TDATA, TUSER, TID, TDEST>
typedef hls::stream<AXI_VALUE_8> AXI_STREAM_8;

typedef ap_axiu<14,1,1,1> AXI_VALUE_14;		// <TDATA, TUSER, TID, TDEST>
typedef hls::stream<AXI_VALUE_14> AXI_STREAM_14;


// ****************************************************************************
// *** Functions ***
// ****************************************************************************

// Top-Function
void ecc(AXI_STREAM_8 &inData, AXI_STREAM_8 &outMean, AXI_STREAM_14 &outVar);

