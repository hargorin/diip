//
//  wallis.cpp
//
//  Created by Jan Stocker on 11.04.2018
//  Copyright © 2018 Jan Stocker. All rights reserved.
//

#include "../inc/wallis.h"

// Mean
apuint8_t Cal_Mean(apuint19_t sum_Pixel);

// Variance
apuint16_t Cal_Variance(apuint16_t mean2, apuint27_t sum_pixel2);

// Wallis Filter
apuint8_t Wallis_Filter(apuint8_t v_pixel, apuint8_t n_Mean, apuint14_t n_Var,
						apuint8_t g_Mean, apuint14_t g_Var, ap_ufixed<5,1> contrast,
						ap_ufixed<5,1> brightness);


void wallis(AXI_STREAM_IN &inData, AXI_STREAM_OUT &outData,
			apuint8_t g_Mean, apuint14_t g_Var, ap_ufixed<5,1> contrast,
			ap_ufixed<5,1> brightness) {

	g_Mean = 127;
	g_Var = 3600;
	contrast = 0.82;
	brightness = 0.49;
	
	// ************************************************************************
	// Variables
	AXI_VALUE_IN inPixel;
	AXI_VALUE_OUT outPixel;

	static apuint19_t sum_Pixel;
	static apuint27_t sum_Pixel2;
	static apuint8_t n_Mean;
	static apuint14_t n_Var;
	static apuint168_t pixel[WIN_SIZE];

	static apuint8_t u_pixel;

	// ************************************************************************
	// Initialization
	// ************************************************************************
	// Read data and calculate mean
	sum_Pixel = 0;
	sum_Pixel2 = 0;
	loop_rdata:for(uint16_t i = 0; i < WIN_LENGTH; i++) {
		inPixel = inData.read();
		pixel[i] = inPixel.data;

		loop_sum:for(uint8_t k = 0; k < WIN_LENGTH; k++) {
			static apuint16_t tmp_pow;
			u_pixel = ((pixel[i] >> (8 * k)) & 0xFF);
			sum_Pixel += u_pixel;				// sum of the Pixels
			tmp_pow = u_pixel * u_pixel;
			sum_Pixel2 += tmp_pow;
		}

	}

	// ************************************************************************
	// Mean
	n_Mean = Cal_Mean(sum_Pixel);
	//printf("HW: %d\n", (uint8_t)n_Mean);
	// ************************************************************************
	// Variance
	n_Var = Cal_Variance(n_Mean * n_Mean, sum_Pixel2);

	// ************************************************************************
	// Wallis Filter
	u_pixel = ((pixel[WIN_CENTER] >> WIN_SHIFT) & 0xFF);
	outPixel.data = Wallis_Filter(u_pixel, n_Mean, n_Var, g_Mean, g_Var,
									contrast, brightness);

	// ************************************************************************
	// Output
	outData.write(outPixel);


	// ************************************************************************
	// Loop
	// ************************************************************************
	loop_while:while(!inPixel.last) {
		// ********************************************************************
		// Organize new Data
		// Subtract old pixel data from sum_Pixel
		loop_subData:for(uint16_t i = 0; i < WIN_LENGTH; i++) {
			static apuint16_t tmp_pow;
			u_pixel = ((pixel[0] >> (8 * i)) & 0xFF);
			sum_Pixel -= u_pixel;				// sum of the Pixels
			tmp_pow = u_pixel * u_pixel;
			sum_Pixel2 -= tmp_pow;
		}

		// Copy data
		loop_strData:for(uint16_t i = 0; i < (WIN_LENGTH - 1); i++) {
			pixel[i] = pixel[i+1];
		}

		// Add new data and calculate new sub_Pixel
		inPixel = inData.read();
		pixel[WIN_LENGTH - 1] = inPixel.data;

		loop_addData:for(uint16_t i = 0; i < WIN_LENGTH; i++) {
			static apuint16_t tmp_pow;
			u_pixel = ((pixel[WIN_LENGTH - 1] >> (8 * i)) & 0xFF);
			sum_Pixel += u_pixel;				// sum of the Pixels
			tmp_pow = u_pixel * u_pixel;
			sum_Pixel2 += tmp_pow;
		}


		// ********************************************************************
		// Mean
		n_Mean = Cal_Mean(sum_Pixel);
		//printf("HW: %d\n", (uint8_t)n_Mean);
		// ********************************************************************
		// Variance
		n_Var = Cal_Variance(n_Mean * n_Mean, sum_Pixel2);

		// ********************************************************************
		// Wallis Filter
		u_pixel = ((pixel[WIN_CENTER] >> WIN_SHIFT) & 0xFF);
		outPixel.data = Wallis_Filter(u_pixel, n_Mean, n_Var, g_Mean, g_Var,
										contrast, brightness);

		// ********************************************************************
		// Output
		outPixel.last = inPixel.last;
		outData.write(outPixel);
	}

}

/*
 * Calculate the mean
 */
apuint8_t Cal_Mean(apuint19_t sum_Pixel) {
	apuint8_t mean;

	mean = (sum_Pixel / WIN_SIZE);

	return mean;
}


/*
 * Calculate the variance
 */
apuint16_t Cal_Variance(apuint16_t mean2, apuint27_t sum_pixel2) {
	apuint16_t var;
	
	var = sum_pixel2 / WIN_SIZE - mean2;

	return var;
}


/*
 * Calculate the Wallis Filter
 */
apuint8_t Wallis_Filter(apuint8_t v_pixel, apuint8_t n_Mean, apuint14_t n_Var,
						apuint8_t g_Mean, apuint14_t g_Var, ap_ufixed<5,1> contrast,
						ap_ufixed<5,1> brightness) {

	ap_int<23> tmp_Num;
	ap_int<23> fp_Num;
	ap_uint<14> fp_nVar;
	ap_uint<8> fp_nMean;
	ap_uint<15> fp_Var;
	ap_ufixed<18,1> fp_Den;
	ap_int<23> fp_Div;
	ap_int<23> w_Pixel;

	ap_uint<8> w_gMean = brightness * g_Mean;
	ap_uint<14> w_gVar = (1-contrast) * g_Var;

	tmp_Num = (v_pixel - n_Mean) * g_Var;
	fp_Num = tmp_Num * contrast;
	fp_nVar = contrast * n_Var;
	fp_nMean = (1-brightness) * n_Mean;
	fp_Var = fp_nVar + w_gVar;

	ap_ufixed<18,1> rec = 1.0;
	fp_Den = rec/fp_Var;
	fp_Div = fp_Num * fp_Den;

	w_Pixel = fp_Div + w_gMean + fp_nMean;
	if(w_Pixel > 255) w_Pixel = 255;
	if(w_Pixel < 0) w_Pixel = 0;

	return (apuint8_t)w_Pixel;
}




