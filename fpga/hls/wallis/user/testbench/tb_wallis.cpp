//
//  tb_wallis.cpp
//
//  Created by Jan Stocker on 11.04.2018
//  Copyright © 2018 Jan Stocker. All rights reserved.
//

#include "../includes/wallis.h"

#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
using namespace cv;

#define INPUT_IMAGE "landscape.jpg"
#define G_MEAN 		127
#define G_VAR 		3600 // STD = 60
#define CONTRAST 	0.75	//0.75
#define BRIGHTNESS	1	//0.8

uint8_t C_Mean(uint8_t *pixel);
uint16_t C_Var(uint8_t *pixel, uint8_t mean);
uint8_t C_Wallis(uint8_t v_pixel, uint8_t n_mean, uint16_t n_var, uint8_t g_mean, uint16_t g_var, float brightness, float contrast);

int main(int argc, const char * argv[]) {

	// ************************************************************************
	// Variables
	AXI_STREAM inDataFIFO;
	AXI_STREAM outData;
	AXI_VALUE inData;

	// C-Variables
	uint8_t c_pixel[LENGTH];
	uint8_t c_mean;
	uint16_t c_var;
	uint8_t c_wallis;

	// Read Image
	Mat src_img = imread(INPUT_IMAGE);
	if (!src_img.data) {
		printf("***********************************************************\n");
		printf("	ERROR: could not open or find the input image!\n");
		printf("***********************************************************\n");
		return -1;
	}

	// Edit Image
	Mat src_gray;
	cvtColor(src_img, src_gray, CV_BGR2GRAY);
	uint16_t img_width = src_gray.cols;
	uint16_t img_length = src_gray.rows;
	uint16_t g_width = (img_width - WIN_SIZE + 1);
	uint16_t g_length = (img_length - WIN_SIZE + 1);


	// Puts data into FIFO
	//uint16_t offset = 0;
	uint16_t index = 0;
	for(uint16_t offset = 0; offset < g_length; offset++) {
		for (uint16_t x = 0; x < img_width; x++) {
		//for (uint16_t x = 0; x < WIN_SIZE; x++) {
			for (uint16_t y = 0; y < WIN_SIZE; y++) {
				inData.data = src_gray.at<apuint8_t>(Point(x, (y + offset)));
				//c_pixel[index++] = inData.data;
				if((x == img_width - 1) && (y == WIN_SIZE - 1)){
					inData.last = 1;
				}
				inDataFIFO.write(inData);
			}
		}

		wallis(inDataFIFO, outData, G_MEAN, G_VAR, CONTRAST, BRIGHTNESS);
	}




//
//
//
//	uint16_t index = 0;
//	for(uint16_t offset = 0; offset < g_length; offset++) {
//		for (uint16_t x = 0; x < img_width; x++) {
//		//for (uint16_t x = 0; x < WIN_SIZE; x++) {
//			for (uint16_t y = 0; y < WIN_SIZE; y++) {
//				inData.data = src_gray.at<apuint8_t>(Point(x, (y + offset)));
//				//c_pixel[index++] = inData.data;
//				inDataFIFO.write(inData);
//			}
//		}
//
//		while(!inDataFIFO.empty()) {
//			wallis(inDataFIFO, outData, G_MEAN, G_VAR, CONTRAST, BRIGHTNESS, g_width);
//		}
//	}
//

	// ************************************************************************
	// C Testbench
	// ************************************************************************
	c_mean = C_Mean(c_pixel);
	c_var = C_Var(c_pixel, c_mean);
	c_wallis = C_Wallis(c_pixel[(LENGTH - 1) / 2], c_mean, c_var, G_MEAN, G_VAR, BRIGHTNESS, CONTRAST);



	// ************************************************************************
	// Output
	uint16_t dst_img_length = (img_length - WIN_SIZE + 1);
	uint16_t dst_img_width = (img_width - WIN_SIZE + 1);
	uint8_t w_data[dst_img_length * dst_img_width];
	uint32_t i = 0;
	
	while(!outData.empty()) {
		AXI_VALUE tmp = outData.read();
		w_data[i++] = (uint8_t)tmp.data;
		printf("SW = %d | HW = %d\n", c_wallis, (uint8_t)tmp.data);
		//printf("i=%d\n",i);
	}

	// Show image
/*	Mat dst_img = Mat(g_length, g_width, CV_8UC1, w_data);

	imwrite("wallis_landscape.jpg", dst_img);
	if (getenv("DISPLAY") != NULL)
	{
		imshow( "Original", src_gray );
		imshow( "Wallis", dst_img );
		waitKey(0);
	}*/


    return 0;
}

uint8_t C_Mean(uint8_t *pixel) {
	uint32_t c_sumPixel = 0;
	uint8_t mean = 0;

	for(uint16_t k = 0; k < LENGTH; k++) {
		c_sumPixel += pixel[k];
	}

	mean = c_sumPixel / LENGTH;
	return mean;
}

uint16_t C_Var(uint8_t *pixel, uint8_t mean) {
	uint32_t c_sumPow = 0;
	uint16_t var = 0;

	for(uint16_t k = 0; k < LENGTH; k++) {
		c_sumPow += (pixel[k] - mean) * (pixel[k] - mean);
	}

	var = c_sumPow / (LENGTH - 1);
	return var;
}

uint8_t C_Wallis(uint8_t v_pixel, uint8_t n_mean, uint16_t n_var, uint8_t g_mean, uint16_t g_var, float brightness, float contrast) {
	float tmp_Num;
	float fp_Num;
	float fp_nVar;
	float fp_nMean;
	float fp_Var;
	float fp_Den;
	float fp_Div;
	float w_Pixel;


	float w_gMean = brightness * g_mean;
	float w_gVar = (1-contrast) * g_var;

	// int23 = (uint8 - uint8) * uint14
	tmp_Num = (v_pixel - n_mean) * g_var;
	// <27,23> = int23 * <5,1>
	fp_Num = tmp_Num * contrast;
	// <18,14> = <5,1> * uint14
	fp_nVar = contrast * n_var;
	// <12,8> = (1 - <5,1>) * uint8
	fp_nMean = (1-brightness) * n_mean;
	// <19,15> = <18,14> + <18,14>
	fp_Var = fp_nVar + w_gVar;
	// <20,5> = 1/ <19,15>
	fp_Den = 1/fp_Var;
	// <35,29> = <27,23> * <20,5>
	fp_Div = fp_Num * fp_Den;
	// <36,30> = <35,29> + <12,8> +  <12,8>
	w_Pixel = fp_Div + w_gMean + fp_nMean;

	return (apuint8_t)w_Pixel;
}


