//
//  wallis.cpp
//
//  Created by Jan Stocker on 11.04.2018
//  Copyright © 2018 Jan Stocker. All rights reserved.
//

#include "../includes/wallis.h"


void wallis(AXI_STREAM &inData, AXI_STREAM &outData, 
			apuint8_t g_Mean, apuint16_t g_Var, float contrast, float brightness) {
	
	#pragma HLS INTERFACE axis port=inData
	#pragma HLS INTERFACE axis port=outData


	// ************************************************************************
	// Variables
	AXI_VALUE inPixel;
	AXI_VALUE outPixel;

	uint16_t length = WIN_SIZE * WIN_SIZE;
	uint32_t sum_Pixel;
	apuint8_t n_Mean, n_Var;
	apuint8_t pixel[length];

	// ************************************************************************
	// Initalization
	// ************************************************************************
	// Read data and calculate mean
	for(uint16_t i = 0; i < length; i++) {
		//#pragma HLS PIPELINE

		inPixel = inData.read();
		pixel[i] = inPixel.data;

		sum_Pixel += pixel[i];

		//printf("Pixel=%d\n",(uint8_t)pixel[i]);
	}

	// ************************************************************************
	// Mean
	n_Mean = Cal_Mean(sum_Pixel, length);

	// ************************************************************************
	// Variance
	n_Var = Cal_Variance(n_Mean, pixel, length);

	// ************************************************************************
	// Wallis Filter
	outPixel.data = Wallis_Filter(pixel, n_Mean, n_Var, g_Mean, g_Var, 
									contrast, brightness, length);

	// ************************************************************************
	// Output
	outData.write(outPixel);
	//printf("Wallis = %d\n",(uint8_t)outPixel.data);


	// ************************************************************************
	// Loop
	// ************************************************************************
	while(!inData.empty()) {
		
		// ********************************************************************
		// Organise new Data 

		// Old data delete
		apuint8_t tmp_Pixel[length];
		for(uint16_t i = 0; i < (length - WIN_SIZE); i++) {
			//#pragma HLS UNROLL

			tmp_Pixel[i] = pixel[i+WIN_SIZE];
		}

		// Add new data and calculate new mean
		for(uint16_t i = 0; i < WIN_SIZE; i++) {
			//#pragma HLS PIPELINE

			inPixel = inData.read();
			tmp_Pixel[i + (length - WIN_SIZE)] = inPixel.data;

			sum_Pixel -= pixel[i];
			sum_Pixel += tmp_Pixel[i + (length - WIN_SIZE)];

			//printf("Pixel=%d\n",(uint8_t)pixel[i]);
		}

		// Set new data
		for(uint16_t i = 0; i < length; i++) {
			//#pragma HLS UNROLL

			pixel[i] = tmp_Pixel[i];
		}

		// ********************************************************************
		// Mean
		n_Mean = Cal_Mean(sum_Pixel, length);

		// ********************************************************************
		// Variance
		n_Var = Cal_Variance(n_Mean, pixel, length);

		// ********************************************************************
		// Wallis Filter
		outPixel.data = Wallis_Filter(pixel, n_Mean, n_Var, g_Mean, g_Var, 
										contrast, brightness, length);

		// ********************************************************************
		// Output
		outData.write(outPixel);
		//printf("Wallis = %d\n",(uint8_t)outPixel.data);
	}

}


/*
 * Calculate the mean
 */
apuint8_t Cal_Mean(uint32_t sum_Pixel, uint16_t length) {
	//#pragma HLS INLINE
	
	apuint8_t mean;

	mean = apuint8_t(sum_Pixel / length);
	
	//printf("mean = %d\n",(uint8_t)mean);

	return mean;
}


/*
 * Calculate the variance
 */
apuint16_t Cal_Variance(apuint8_t mean, apuint8_t *pixel, uint16_t length) {
	//#pragma HLS INLINE
	
	uint32_t sum_Pow = 0;
	apuint16_t tmp_pow = 0;
	apuint16_t var;
	
	for(uint16_t i = 0; i < length; i++) {
		//#pragma HLS UNROLL

		tmp_pow = pow((pixel[i] - mean), 2);
		sum_Pow += tmp_pow;
	}

	var = apuint16_t(sum_Pow / (length - 1));

	//printf("Var = %d\n",(uint16_t)var);
	//printf("STD = %d\n",(uint16_t)sqrt(var));

	return var;
}


/*
 * Calculate the Wallis Filter
 */
apuint8_t Wallis_Filter(apuint8_t *pixel, apuint8_t n_Mean, apuint16_t n_Var, 
						apuint8_t g_Mean, apuint16_t g_Var, float contrast,
						float brightness, uint16_t length) {
	//#pragma HLS INLINE

	float tmp_gMean = 0.0, tmp_nMean = 0.0;
	float tmp_gVar = 0.0, tmp_nVar = 0.0;
	float tmp_Num = 0.0, w_pixel = 0.0;

	static apuint16_t pos = (length - 1) / 2;

	tmp_Num = (pixel[pos] - n_Mean) * contrast * g_Var;
	tmp_nVar = contrast * n_Var;
	tmp_gVar = (1-contrast) * g_Var;
	tmp_gMean = brightness * g_Mean;
	tmp_nMean = (1-brightness) * n_Mean;

	w_pixel = tmp_Num / (tmp_nVar + tmp_gVar) + tmp_gMean + tmp_nMean;

	return (apuint8_t)w_pixel;
}



