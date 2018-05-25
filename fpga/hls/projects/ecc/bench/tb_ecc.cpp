//
//  tb_ecc.cpp
//
//  Created by Jan Stocker on 18.05.2018
//  Copyright © 2018 Jan Stocker. All rights reserved.
//

#include "../inc/ecc.h"

#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <iostream>
using namespace cv;

#define INPUT_IMAGE "room.jpg"


uint8_t C_Mean(uint8_t *pixel);
uint16_t C_Var(uint8_t *pixel, uint8_t mean);

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
	//uint16_t img_width = src_gray.cols;
	//uint16_t img_height = src_gray.rows;
	uint16_t img_width = 30;
	uint16_t img_height = 30;

	uint16_t g_height = (img_height - WIN_LENGTH + 1);
	uint16_t g_width = (img_width - WIN_LENGTH + 1);



	// ************************************************************************
	// HW - Testbench
	// ************************************************************************
	// Variables
	AXI_STREAM_8 inDataFIFO;
	AXI_STREAM_8 outMean;
	AXI_STREAM_14 outVar;
	AXI_VALUE_8 inData;

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
		ecc(inDataFIFO, outMean, outVar);
		inData.last = 0;
	}


	// ************************************************************************
	// C - Testbench
	// ************************************************************************
	// Variables
	uint8_t c_pixel[WIN_SIZE];
	uint8_t c_mean[g_height * g_width];
	uint16_t c_var[g_height * g_width];
	uint32_t index = 0;

	for(uint16_t y_offset = 0; y_offset < g_height; y_offset++) {
		for(uint16_t x_offset = 0; x_offset < g_width; x_offset++) {
			uint16_t i_pixel = 0;
			for (uint8_t x = 0; x < WIN_LENGTH; x++) {
				for (uint8_t y = 0; y < WIN_LENGTH; y++) {
					c_pixel[i_pixel] = src_gray.at<uint8_t>(Point(x + x_offset, (y + y_offset)));
					i_pixel++;
				}

			}

			c_mean[index] = C_Mean(c_pixel);
			c_var[index] = C_Var(c_pixel, c_mean[index]);
			index++;
		}
	}



	//************************************************************************
	//Compare results from output stream
	//************************************************************************
	uint8_t hw_mean;
	uint16_t hw_var;
	uint32_t i = 0;

	int err = 0;
	bool oDatErr = false;

	// Mean
	while(!outMean.empty()) {
		AXI_VALUE_8 tmp = outMean.read();
		hw_mean = (uint8_t)tmp.data;

		if(c_mean[i] != hw_mean) {
			printf("ERROR[outMean] HW and SW results mismatch\n");
			printf("ERROR[outMean] i = %d SW = %d HW= %d\n",i,c_mean[i],hw_mean);
			err = -1; oDatErr = true;
		}
		i++;
	}

	// Variance
	i = 0;
	while(!outVar.empty()) {
		AXI_VALUE_14 tmp = outVar.read();
		hw_var = (uint16_t)tmp.data;

		if(c_var[i] != hw_var) {
			printf("ERROR[outVar] HW and SW results mismatch\n");
			printf("ERROR[outVar] i = %d SW = %d HW= %d\n",i,c_var[i],hw_var);
			err = -1; oDatErr = true;
		}
		i++;
	}

	if(err) {
		printf("Failed\n");
		printf("End Testbench\n");
		printf("***************\n");
		return err;
	}

	printf("Success! HW and SW results match\n");
	printf("End Testbench\n");
	printf("***************\n");
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
		c_sumPow += (pixel[k] - mean) * (pixel[k] - mean);
	}

	var = c_sumPow / (WIN_SIZE - 1);
	return var;
}



