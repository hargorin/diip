//
//  wallis.cpp
//
//  Created by Jan Stocker on 11.04.2018
//  Copyright © 2018 Jan Stocker. All rights reserved.
//

#include "../includes/wallis.h"


void wallis(AXI_STREAM &inData, AXI_STREAM &outData, 
			apuint8_t g_Mean, apuint16_t g_Var, float contrast, float brightness,
			apuint16_t g_Width) {
	
	// ************************************************************************
	// Variables
	AXI_VALUE inPixel;
	AXI_VALUE outPixel;

	static apuint14_t sum_Pixel;
	static apuint8_t n_Mean, n_Var;
	static apuint8_t pixel[LENGTH];
	static apuint8_t tmp_Pixel[LENGTH];

	// ************************************************************************
	// Initialization
	// ************************************************************************
	// Read data and calculate mean
	sum_Pixel = 0;
	loop_rdata:for(uint16_t i = 0; i < LENGTH; i++) {
		inPixel = inData.read();
		pixel[i] = inPixel.data;

		sum_Pixel += pixel[i];
	}

	// ************************************************************************
	// Mean
	n_Mean = Cal_Mean(sum_Pixel);

	// ************************************************************************
	// Variance
	n_Var = Cal_Variance(n_Mean, pixel);

	// ************************************************************************
	// Wallis Filter
	//outPixel.data = Wallis_Filter(pixel, n_Mean, n_Var, g_Mean, g_Var,
	//								contrast, brightness);

	// ************************************************************************
	// Output
	outPixel.data = n_Var;
	outData.write(outPixel);


	// ************************************************************************
	// Loop
	// ************************************************************************
/*	for(uint16_t k = 0; k < (g_Width - 1); k++) {
		//#pragma HLS DATAFLOW
		//#pragma HLS LOOP_FLATTEN off
		//#pragma HLS DEPENDENCE variable=pixel array inter RAW true
		//#pragma HLS DEPENDENCE variable=tmp_Pixel array inter WAR true

		// ********************************************************************
		// Organize new Data

		// Old data delete
		for(uint16_t i = 0; i < (LENGTH - WIN_SIZE); i++) {
			#pragma HLS UNROLL

			tmp_Pixel[i] = pixel[i+WIN_SIZE];
		}

		// Add new data and calculate new mean
		for(uint16_t i = 0; i < WIN_SIZE; i++) {
			#pragma HLS PIPELINE

			inPixel = inData.read();
			tmp_Pixel[i + (LENGTH - WIN_SIZE)] = inPixel.data;

			sum_Pixel -= pixel[i];
			sum_Pixel += tmp_Pixel[i + (LENGTH - WIN_SIZE)];
		}

		// Set new data
		for(uint16_t i = 0; i < LENGTH; i++) {
			#pragma HLS UNROLL

			pixel[i] = tmp_Pixel[i];
		}

		// ********************************************************************
		// Mean
		n_Mean = Cal_Mean(sum_Pixel);

		// ********************************************************************
		// Variance
		n_Var = Cal_Variance(n_Mean, pixel);

		// ********************************************************************
		// Wallis Filter
		outPixel.data = Wallis_Filter(pixel, n_Mean, n_Var, g_Mean, g_Var, 
										contrast, brightness);

		// ********************************************************************
		// Output
		outData.write(outPixel);
	}*/

}


/*
 * Calculate the mean
 */
apuint8_t Cal_Mean(apuint14_t sum_Pixel) {
	apuint8_t mean;

	mean = (apuint8_t)(sum_Pixel / LENGTH);

	return mean;
}


/*
 * Calculate the variance
 */
apuint35_t Cal_Variance(apuint8_t mean, apuint8_t *pixel) {
	apuint40_t sum_Pow = 0;
	apuint16_t tmp_Sub;
	apuint32_t tmp_Pow;
	apuint16_t var;
	
	loop_variance:for(uint16_t i = 0; i < LENGTH; i++) {
		tmp_Sub = (pixel[i] - mean);
		tmp_Pow = (tmp_Sub * tmp_Sub);
		sum_Pow = sum_Pow + tmp_Pow;
		//sum_Pow += (pixel[i] - mean) * (pixel[i] - mean);
	}

	var = apuint35_t(sum_Pow / (LENGTH - 1));

	return var;
}


/*
 * Calculate the Wallis Filter
 */
apuint8_t Wallis_Filter(apuint8_t *pixel, apuint8_t n_Mean, apuint16_t n_Var, 
						apuint8_t g_Mean, apuint16_t g_Var, float contrast,
						float brightness) {

	float tmp_gMean = 0.0, tmp_nMean = 0.0;
	float tmp_gVar = 0.0, tmp_nVar = 0.0;
	float tmp_Num = 0.0, w_pixel = 0.0;

	static apuint16_t pos = (LENGTH - 1) / 2;

	tmp_Num = (pixel[pos] - n_Mean) * contrast * g_Var;
	tmp_nVar = contrast * n_Var;
	tmp_gVar = (1-contrast) * g_Var;
	tmp_gMean = brightness * g_Mean;
	tmp_nMean = (1-brightness) * n_Mean;

	w_pixel = tmp_Num / (tmp_nVar + tmp_gVar) + tmp_gMean + tmp_nMean;

	return (apuint8_t)w_pixel;
}



