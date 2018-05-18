//
//  ecc.cpp
//
//  Created by Jan Stocker on 11.04.2018
//  Copyright © 2018 Jan Stocker. All rights reserved.
//

#include "../inc/ecc.h"

// Mean
apuint8_t Cal_Mean(apuint19_t sum_Pixel);

// Variance
apuint14_t Cal_Variance(apuint8_t mean, apuint8_t *pixel);



void ecc(AXI_STREAM_8 &inData, AXI_STREAM_8 &outMean, AXI_STREAM_14 &outVar) {

	// ************************************************************************
	// Variables
	AXI_VALUE_8 inPixel;
	AXI_VALUE_8 out_mean;
	AXI_VALUE_14 out_var;

	static apuint19_t sum_Pixel;
	static apuint8_t n_Mean;
	static apuint14_t n_Var;
	static apuint8_t pixel[WIN_SIZE];
	static apuint8_t tmp_Pixel[WIN_SIZE];


	// ************************************************************************
	// Initialization
	// ************************************************************************
	// Read data and calculate mean
	sum_Pixel = 0;
	loop_rdata:for(uint16_t i = 0; i < WIN_SIZE; i++) {
		inPixel = inData.read();
		pixel[i] = inPixel.data;

		sum_Pixel += pixel[i];
	}

	// ************************************************************************
	// Mean
	n_Mean = Cal_Mean(sum_Pixel);
	out_mean.data = n_Mean;

	// ************************************************************************
	// Variance
	n_Var = Cal_Variance(n_Mean, pixel);
	out_var.data = n_Var;

	// ************************************************************************
	// Output
	outMean.write(out_mean);
	outVar.write(out_var);



	// ************************************************************************
	// Loop
	// ************************************************************************
	loop_while:while(!inData.empty()) {
		// ********************************************************************
		// Organize new Data
		// Old data delete
		loop_strData:for(uint16_t i = 0; i < (WIN_SIZE - WIN_LENGTH); i++) {
			tmp_Pixel[i] = pixel[i+WIN_LENGTH];
		}

		// Add new data and calculate new mean
		loop_addData:for(uint16_t i = 0; i < WIN_LENGTH; i++) {
			inPixel = inData.read();
			tmp_Pixel[i + (WIN_SIZE - WIN_LENGTH)] = inPixel.data;

			sum_Pixel -= pixel[i];
			sum_Pixel += tmp_Pixel[i + (WIN_SIZE - WIN_LENGTH)];
		}

		// Set new data
		loop_setData:for(uint16_t i = 0; i < WIN_SIZE; i++) {
			pixel[i] = tmp_Pixel[i];
		}

		// ************************************************************************
		// Mean
		n_Mean = Cal_Mean(sum_Pixel);
		out_mean.data = n_Mean;
		out_mean.last = inPixel.last;

		// ************************************************************************
		// Variance
		n_Var = Cal_Variance(n_Mean, pixel);
		out_var.data = n_Var;
		out_var.last = inPixel.last;

		// ************************************************************************
		// Output
		outMean.write(out_mean);
		outVar.write(out_var);
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
apuint14_t Cal_Variance(apuint8_t mean, apuint8_t *pixel) {
	apuint29_t sum_Pow = 0;
	apint9_t tmp_Sub;
	apuint18_t tmp_Pow;
	apuint14_t var;

	loop_variance:for(uint16_t i = 0; i < WIN_SIZE; i++) {
		tmp_Sub = (pixel[i] - mean);
		tmp_Pow = (tmp_Sub * tmp_Sub);
		sum_Pow = sum_Pow + tmp_Pow;
	}

	var = (sum_Pow / (WIN_SIZE - 1));

	return var;
}



