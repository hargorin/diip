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
apuint8_t Wallis_Filter(apuint8_t iPxl, apuint8_t n_Mean, apuint14_t n_Var,
						apuint8_t g_Mean, apuint14_t g_Var, ap_ufixed<5,1,AP_RND> contrast,
						ap_ufixed<5,1,AP_RND> brightness);


void wallis(AXI_STREAM &inData, AXI_STREAM &outData, 
			apuint8_t g_Mean, apuint14_t g_Var, ap_ufixed<5,1,AP_RND> contrast,
			ap_ufixed<5,1,AP_RND> brightness) {

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
apuint8_t Wallis_Filter(apuint8_t iPxl, apuint8_t n_Mean, apuint14_t n_Var,
						apuint8_t g_Mean, apuint14_t g_Var, ap_ufixed<5,1,AP_RND> contrast,
						ap_ufixed<5,1,AP_RND> brightness) {

	apint23_t tmp_Num;
	apint23_t num;
	apuint14_t c_nVar;
	apuint8_t bi_nMean;
	apuint15_t den_Var;
	ap_ufixed<18,1> den;
	apint23_t div;
	apint23_t w_Pixel;

	apuint8_t b_gMean = brightness * g_Mean;
	apuint14_t ci_gVar = (1 - contrast) * g_Var;

	tmp_Num = (apint23_t)((iPxl - n_Mean) * g_Var);
	num = tmp_Num * contrast;
	c_nVar = contrast * n_Var;
	bi_nMean = (1 - brightness) * n_Mean;
	den_Var = (apuint15_t)(c_nVar + ci_gVar);

	ap_ufixed<18,1> rec = 1.0;
	den = rec / den_Var;
	div = num * den;

	w_Pixel = div + b_gMean + bi_nMean;
	if(w_Pixel > 255) w_Pixel = 255;
	if(w_Pixel < 0) w_Pixel = 0;

	return (apuint8_t)w_Pixel;
}
