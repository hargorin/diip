//
//  wallis.cpp
//
//  Created by Jan Stocker on 11.04.2018
//  Copyright © 2018 Jan Stocker. All rights reserved.
//

#include "../includes/wallis.h"


void wallis(AXI_STREAM &inData, AXI_STREAM &outData, 
			apuint8_t g_Mean, apuint16_t g_Var, ap_fixed<7,1> contrast,
			ap_fixed<7,1> brightness, apuint16_t g_Width) {
	
	// ************************************************************************
	// Variables
	AXI_VALUE inPixel;
	AXI_VALUE outPixel;

	static apuint14_t sum_Pixel;
	static apuint8_t n_Mean, n_Var;
	static apuint8_t pixel[LENGTH];
	static apuint8_t tmp_Pixel[LENGTH];

	static float fBrightness = (float)brightness;
	static float fContrast = (float)contrast;
	//static float w_gMean = fBrightness * g_Mean;
	//static float w_gVar = (1-fContrast) * g_Var;
	static apuint11_t pos_Pixel = (LENGTH - 1) / 2;

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
	outPixel.data = Wallis_Filter(pixel[pos_Pixel], n_Mean, n_Var, g_Mean, g_Var,
									fContrast, fBrightness);

	// ************************************************************************
	// Output
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
apuint8_t Wallis_Filter(apuint8_t v_pixel, apuint8_t n_Mean, apuint35_t n_Var,
						apuint8_t g_Mean, apuint16_t g_Var, float fContrast,
						float fBrightness) {
	float tmp_Num = 0.0;
	//float fp_nVar = 0.0;
	float fp_Mean = 0.0;
	float fp_Var = 0.0;
	float fp_Den = 0.0;
	float fp_Div = 0.0;
	float w_Pixel = 0.0;

	tmp_Num = (v_pixel - n_Mean) * g_Var * fContrast;
	fp_Var = fContrast * n_Var + (1-fContrast)*g_Var;
	fp_Mean = fBrightness * g_Mean + (1-fBrightness) * n_Mean;
	//fp_Var = fp_nVar + w_gVar;
	fp_Den = 1/fp_Var;
	fp_Div = tmp_Num * fp_Den;
	w_Pixel = fp_Div + fp_Mean;

	return (apuint8_t)w_Pixel;

}

apuint8_t Wallis_Filter(apuint8_t v_pixel, apuint8_t n_Mean, apuint35_t n_Var,
						apuint8_t g_Mean, apuint16_t g_Var, ap_fixed<5,1> contrast,
						ap_fixed<5,1> brightness, apuint8_t w_gMean, apuint16_t w_gVar) {

	apint48_t tmp_Num;
	ap_fixed<53,49> fp_Num;
	ap_ufixed<40,36> fp_nVar;
	ap_ufixed<12,8> fp_nMean;
	ap_ufixed<40,36> fp_Var;
	ap_fixed<40,4> fp_Den;
	ap_fixed<52,48> fp_Div;
	ap_ufixed<52,48> w_Pixel;

	// int48 = (uint8 - uint8) * uint16
	tmp_Num = (v_pixel - n_Mean) * g_Var;
	// <53,49> = int48 * <5,1>
	fp_Num = tmp_Num * contrast;
	// <40,36 = <5,1> * uint35
	fp_nVar = contrast * n_Var;
	// <12,8> = (1 - <5,1>) * uint8
	fp_nMean = (1-brightness) * n_Mean;
	// <40,36> = <39,35> + uint16
	fp_Var = fp_nVar + w_gVar;
	// <40,4> = 1/ <40,36
	fp_Den = 1/fp_Var;
	// <52,48> = <52,48> * <40,4>
	fp_Div = fp_Num * fp_Den;
	// <52,48> = <52,48> + uint8 +  <12,8>
	w_Pixel = fp_Div + w_gMean + fp_nMean;

	return (apuint8_t)w_Pixel;
}



