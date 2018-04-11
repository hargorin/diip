//
//  sobel.cpp
//
//  Created by Jan Stocker on 08/11/17.
//  Copyright © 2017 Jan Stocker. All rights reserved.
//

#include "../includes/sobel.h"


void sobel_abs(uint64_t pixel_r0[block_width], uint64_t pixel_r1[block_width], uint64_t pixel_r2[block_width],
				uint64_t cal_pixel[block_width - 2]) {

	#pragma HLS INTERFACE bram port=cal_pixel
	#pragma HLS INTERFACE bram port=pixel_r2
	#pragma HLS RESOURCE variable=pixel_r2 core=RAM_1P_BRAM latency=1
	#pragma HLS INTERFACE bram port=pixel_r1
	#pragma HLS RESOURCE variable=pixel_r1 core=RAM_1P_BRAM latency=1
	#pragma HLS INTERFACE bram port=pixel_r0
	#pragma HLS RESOURCE variable=pixel_r0 core=RAM_1P_BRAM latency=1

	uint8_t p0_row0[8], p0_row1[8], p0_row2[8];
	uint8_t p1_row0[8], p1_row1[8], p1_row2[8];
	uint8_t first_time = 1;
	uint8_t temp_res = 0;
	uint64_t sum_res = 0;

	// ***********************************
	// *** load pixel data from memory ***
	// ***********************************
	for(int k = 0; k < 8; k++) {
		#pragma HLS UNROLL

		p0_row0[k] = (pixel_r0[0] >> (8*k));
		p0_row1[k] = (pixel_r1[0] >> (8*k));
		p0_row2[k] = (pixel_r2[0] >> (8*k));
	}

	for(int i_res = 0; i_res < (block_width-2); i_res++) {
		#pragma HLS PIPELINE II=1

		// ************************************
		// *** load pixel data from  memory ***
		// ************************************
		if(i_res > 0) {
			for(int k = 0; k < 8; k++) {
				p0_row0[k] = p1_row0[k];
				p0_row1[k] = p1_row1[k];
				p0_row2[k] = p1_row2[k];
			}
		}

		for(int k = 0; k < 8; k++) {
			p1_row0[k] = (pixel_r0[i_res+1] >> (8*k));
			p1_row1[k] = (pixel_r1[i_res+1] >> (8*k));
			p1_row2[k] = (pixel_r2[i_res+1] >> (8*k));
		}


		// ***********************************************
		// *** calculate the new pixel with the filter ***
		// ***********************************************
		for (int x = 1; x < 7; x++) {
			temp_res = cal_pixel_value(p0_row0[x-1], p0_row1[x-1], p0_row2[x-1],
										p0_row0[x+1], p0_row1[x+1], p0_row2[x+1],
										p0_row0[x], p0_row2[x]);

			sum_res |= ( ((uint64_t)temp_res) << (8*(x-1)) );
		}


		temp_res = cal_pixel_value(p0_row0[6], p0_row1[6], p0_row2[6],
									p1_row0[0], p1_row1[0], p1_row2[0],
									p0_row0[7], p0_row2[7]);

		sum_res |= ( ((uint64_t)temp_res) << (8*6) );


		temp_res = cal_pixel_value(p0_row0[7], p0_row1[7], p0_row2[7],
									p1_row0[1], p1_row1[1], p1_row2[1],
									p1_row0[0], p1_row2[0]);

		sum_res |= ( ((uint64_t)temp_res) << (8*7) );


		// ******************************
		// *** output pixel in memory ***
		// ******************************
		cal_pixel[i_res] = sum_res;
		sum_res = 0;
	}
}

/*
 * calculate the pixel value with the Sobel algorithm
 */
uint8_t cal_pixel_value(uint8_t pixel_00, uint8_t pixel_10, uint8_t pixel_20, 
						uint8_t pixel_02, uint8_t pixel_12, uint8_t pixel_22, 
						uint8_t pixel_01, uint8_t pixel_21) {
	#pragma HLS INLINE

	int16_t gx, gy, sum;

	// calculate X- and Y-direction
	gx = 	sobel_x[0][0] * pixel_00 +
			sobel_x[1][0] * pixel_10 +
			sobel_x[2][0] * pixel_20 +
			sobel_x[0][2] * pixel_02 +
			sobel_x[1][2] * pixel_12 +
			sobel_x[2][2] * pixel_22;

	gy = 	sobel_y[0][0] * pixel_00 +
			sobel_y[0][1] * pixel_01 +
			sobel_y[0][2] * pixel_02+
			sobel_y[2][0] * pixel_20 +
			sobel_y[2][1] * pixel_21 +
			sobel_y[2][2] * pixel_22;

	// calculate the gradient
	gx = gx < 0 ? -gx : gx; // abs(gx)
	gy = gy < 0 ? -gy : gy; // abs(gy)
	sum = gx + gy;
	sum = sum > 255 ? 255:sum;
	sum = sum < 0 ? 0 : sum;

	return (uint8_t)sum;
}



