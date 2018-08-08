//
//  tb_wallis.cpp
//
//  Created by Jan Stocker on 11.04.2018
//  Copyright © 2018 Jan Stocker. All rights reserved.
//

#include "../inc/wallis.h"

#include <math.h>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <iostream>
using namespace cv;

#define INPUT_IMAGE "room.tif"
#define G_MEAN 		127
#define G_VAR 		3600 // STD = 60
#define CONTRAST 	0.8125 //0.75 0.82
#define BRIGHTNESS	0.5	//0.8 0.49


uint8_t C_Mean(uint8_t *pixel);
uint16_t C_Var(uint8_t *pixel, uint8_t mean);
uint8_t C_Wallis(uint8_t v_pixel, uint8_t n_mean, uint16_t n_var, uint8_t g_mean, uint16_t g_var, float brightness, float contrast);

int main(int argc, const char * argv[]) {

	// Read Image
	Mat src_img = imread(INPUT_IMAGE);
	if (!src_img.data) {
		printf("***********************************************************\n");
		printf("	ERROR: could not open or find the input image!\n");
		printf("***********************************************************\n");
		return 1;
	}

	// Edit Image
	Mat src_gray;
	cvtColor(src_img, src_gray, CV_BGR2GRAY);
	uint16_t img_width = src_gray.cols;
	uint16_t img_height = src_gray.rows;
	//uint16_t img_height = 40;
	//uint16_t img_width = 40;
	uint16_t g_height = (img_height - WIN_LENGTH + 1);
	uint16_t g_width = (img_width - WIN_LENGTH + 1);

	// ************************************************************************
	// Variables
	AXI_STREAM inDataFIFO;
	AXI_STREAM outData;
	AXI_VALUE inData;

	// C-Variables
	uint8_t c_pixel[WIN_SIZE];
	uint8_t c_mean = 0;
	uint16_t c_var = 0;
	uint8_t c_wallis[g_width * g_height];


	// ************************************************************************
	// HW Testbench
	// ************************************************************************
	for(uint16_t offset = 0; offset < g_height; offset++) {
		for (uint16_t x = 0; x < img_width; x++) {
			for (uint16_t y = 0; y < WIN_LENGTH; y++) {
				inData.data = src_gray.at<apuint8_t>(Point(x, (y + offset)));
				if((x == img_width- 1) && (y == WIN_LENGTH - 1)){
					inData.last = 1;
				}
				inDataFIFO.write(inData);
			}
		}
		wallis(inDataFIFO, outData, G_MEAN, G_VAR, CONTRAST, BRIGHTNESS);
		inData.last = 0;
	}


	// ************************************************************************
	// C Testbench
	// ************************************************************************
	uint32_t i_wallis = 0;
	for(uint16_t y_offset = 0; y_offset < g_height; y_offset++) {
		for(uint16_t x_offset = 0; x_offset < g_width; x_offset++) {
			uint16_t i_pixel = 0;
			for (uint8_t x = 0; x < WIN_LENGTH; x++) {
				for (uint8_t y = 0; y < WIN_LENGTH; y++) {
					c_pixel[i_pixel++] = src_gray.at<uint8_t>(Point(x + x_offset, (y + y_offset)));
				}

			}

			c_mean = C_Mean(c_pixel);
			c_var = C_Var(c_pixel, c_mean);
			//printf("Var %2d: %5d\n", i_wallis, c_var);
			c_wallis[i_wallis++] = C_Wallis(c_pixel[(WIN_SIZE - 1) / 2], c_mean, c_var, G_MEAN, G_VAR, BRIGHTNESS, CONTRAST);
		}
	}


	// ************************************************************************
	// Output
	// ************************************************************************
	uint8_t w_data[g_width * g_height];
	uint32_t index_pix = 0;
	uint32_t err = 0;
	uint32_t equal = 0;
	uint32_t plus_1 = 0;
	uint32_t minus_1 = 0;
	
	while(!outData.empty()) {
	//for(uint32_t i = 0; i < (g_length * g_width); i++) {
		AXI_VALUE tmp = outData.read();
		w_data[index_pix] = (uint8_t)tmp.data;

		// ************************************************************************
		// Comparison
		if( w_data[index_pix] >= c_wallis[index_pix]) {
			if(w_data[index_pix] == c_wallis[index_pix]) {
				equal++;
			}
			else if(w_data[index_pix] == (c_wallis[index_pix] + 1)) {
				plus_1++;
			}
			else {
				err++;
			}
		}
		else if(w_data[index_pix] < c_wallis[index_pix]) {
			if(w_data[index_pix] == (c_wallis[index_pix] - 1)) {
				minus_1++;
			}
			else {
				err++;
			}
		}

		index_pix++;
	}

	// mean square error
	float sum = 0;
	float mse = 0;
	float difference = 0;
	for(uint32_t k = 0; k < index_pix; k++) {
		difference = (w_data[k] - c_wallis[k]);
		sum = sum + (difference * difference);
	}
	mse = sum / index_pix;


	printf("***********************************************************\n");
	printf("				START - TESTBENCH\n");
	printf("***********************************************************\n");

	//printf("SW = %d | HW = %d\n", c_wallis[i++], (uint8_t)tmp.data);
	printf("Equal  : %.1f%%\n", 100.0*equal/index_pix);
	printf("Plus 1 : %.1f%%\n", 100.0*plus_1/index_pix);
	printf("Minus 1: %.1f%%\n", 100.0*minus_1/index_pix);
	printf("Error  : %.1f%%\n", 100.0*err/index_pix);
	printf("Total Pixels  : %d - %d\n", (equal + plus_1 + minus_1 + err), index_pix);

	printf("-----------------------------------------------------------\n");
	//printf("MSE	   : %.6f\n", mse);
	printf("RMSE   : %.6f\n", sqrt(mse));
	printf("-----------------------------------------------------------\n");

	printf("***********************************************************\n");
	printf("				END - TESTBENCH\n");
	printf("***********************************************************\n");

	// Show image
/*	Mat hw_dst_img = Mat(g_height, g_width, CV_8UC1, w_data);
	Mat c_dst_img = Mat(g_height, g_width, CV_8UC1, c_wallis);

	imwrite("wallis_hw_room.tif", hw_dst_img);
	imwrite("wallis_sw_room.tif", c_dst_img);
	if (getenv("DISPLAY") != NULL)
	{
		imshow( "Original", src_gray );
		imshow( "HW - Wallis", hw_dst_img );
		imshow( "SW - Wallis", c_dst_img );
		waitKey(0);
	}*/


    return 0;
}


// ****************************************************************************
// Functions
// ****************************************************************************
uint8_t C_Mean(uint8_t *pixel) {
	uint32_t c_sumPixel = 0;
	uint8_t mean = 0;

	for(uint16_t k = 0; k < WIN_SIZE; k++) {
		c_sumPixel += pixel[k];
	}

	mean = c_sumPixel / WIN_SIZE;
	return mean;
}

uint16_t C_Var(uint8_t *pixel, uint8_t mean) {
	uint32_t c_sumPow = 0;
	uint16_t var = 0;

	for(uint16_t k = 0; k < WIN_SIZE; k++) {
		c_sumPow += (pixel[k] * pixel[k]);
	}

	var = (c_sumPow / WIN_SIZE) - (mean*mean);
	return var;
}

uint8_t C_Wallis(uint8_t v_pixel, uint8_t n_mean, uint16_t n_var, uint8_t g_mean, uint16_t g_var, float brightness, float contrast) {
	float w_Pixel;

	float dgb = ((v_pixel - n_mean)*contrast*g_var) / (contrast*n_var+(1-contrast)*g_var);
	w_Pixel = dgb + brightness*g_mean + (1-brightness)*n_mean;

	if(w_Pixel > 255) w_Pixel = 255;
	if(w_Pixel < 0) w_Pixel = 0;

	return (uint8_t)w_Pixel;
}


