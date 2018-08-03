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


void wallis(AXI_STREAM &inData, AXI_STREAM &outData, 
			apuint8_t g_Mean, apuint14_t g_Var, ap_ufixed<5,1> contrast,
			ap_ufixed<5,1> brightness) {

	// ************************************************************************
	// Variables
	AXI_VALUE inPixel;
	AXI_VALUE outPixel;

	static apuint19_t sum_Pixel;
	static apuint27_t sum_Pixel2;
	static apuint8_t n_Mean;
	static apuint14_t n_Var;
	static apuint8_t pixel[WIN_SIZE];

	static apuint10_t pos_Pixel = (WIN_SIZE - 1) / 2;

	// ************************************************************************
	// Initialization
	// ************************************************************************
	// Read data and calculate mean
	sum_Pixel = 0;
	sum_Pixel2 = 0;
	loop_rdata:for(uint16_t i = 0; i < WIN_SIZE; i++) {
		static apuint16_t tmp_pow;
		inPixel = inData.read();
		pixel[i] = inPixel.data;

		sum_Pixel += pixel[i];				// sum of the Pixels
		tmp_pow = pixel[i] * pixel[i];
		sum_Pixel2 += tmp_pow;
	}

	// ************************************************************************
	// Mean
	n_Mean = Cal_Mean(sum_Pixel);

	// ************************************************************************
	// Variance
	n_Var = Cal_Variance(n_Mean * n_Mean, sum_Pixel2);

	// ************************************************************************
	// Wallis Filter
	outPixel.data = Wallis_Filter(pixel[pos_Pixel], n_Mean, n_Var, g_Mean, g_Var,
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
			sum_Pixel -= pixel[i];
			tmp_pow = pixel[i] * pixel[i];
			sum_Pixel2 -= tmp_pow;
		}

		// Copy data
		loop_strData:for(uint16_t i = 0; i < (WIN_SIZE - WIN_LENGTH); i++) {
			pixel[i] = pixel[i+WIN_LENGTH];
		}

		// Add new data and calculate new sub_Pixel
		loop_addData:for(uint16_t i = 0; i < WIN_LENGTH; i++) {
			static apuint16_t tmp_pow;
			inPixel = inData.read();
			pixel[i + (WIN_SIZE - WIN_LENGTH)] = inPixel.data;

			sum_Pixel += pixel[i + (WIN_SIZE - WIN_LENGTH)];
			tmp_pow = pixel[i + (WIN_SIZE - WIN_LENGTH)] * pixel[i + (WIN_SIZE - WIN_LENGTH)];
			sum_Pixel2 += tmp_pow;
		}


		// ********************************************************************
		// Mean
		n_Mean = Cal_Mean(sum_Pixel);

		// ********************************************************************
		// Variance
		n_Var = Cal_Variance(n_Mean * n_Mean, sum_Pixel2);

		// ********************************************************************
		// Wallis Filter
		outPixel.data = Wallis_Filter(pixel[pos_Pixel], n_Mean, n_Var, g_Mean, g_Var,
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
