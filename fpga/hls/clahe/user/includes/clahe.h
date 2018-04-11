//
//  sobel.h
//
//  Created by Jan Stocker on 08/11/17.
//  Copyright © 2017 Jan Stocker. All rights reserved.
//

#ifndef SOBEL_H_
#define SOBEL_H_
#endif

#include <iostream>
#include <stdio.h>
#include <stdint.h>

using namespace std;

// ***********************************************
// *** Global Variables ***
// ***********************************************

// image block size
#define block_width 512 // one 36Kb BRAM -> FPGA Memory Resources

// Filter-Matrix
static int sobel_x [3][3] = {{1,0,-1},
					  	  	 {2,0,-2},
							 {1,0,-1}};

static int sobel_y [3][3] =	{{-1,-2,-1},
					  	  	  {0,0,0},
							  {1,2,1}};


// ***********************************************
// *** Functions ***
// ***********************************************

// Top-Function
void sobel_abs(uint64_t pixel_r0[block_width], uint64_t pixel_r1[block_width], uint64_t pixel_r2[block_width], uint64_t cal_pixel[block_width - 2]);

// calculate pixel
uint8_t cal_pixel_value(uint8_t pixel_00, uint8_t pixel_01, uint8_t pixel_02, uint8_t pixel_10, uint8_t pixel_12, uint8_t pixel_20, uint8_t pixel_21, uint8_t pixel_22);


