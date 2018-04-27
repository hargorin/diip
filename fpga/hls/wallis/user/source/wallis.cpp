//
//  wallis.cpp
//
//  Created by Jan Stocker on 11.04.2018
//  Copyright © 2018 Jan Stocker. All rights reserved.
//

#include "../includes/wallis.h"


void wallis(AXI_STREAM &inData, AXI_STREAM &outData, 
			apuint8_t g_Mean, apuint14_t g_Var, ap_ufixed<5,1> contrast,
			ap_ufixed<5,1> brightness) {
	
	// ************************************************************************
	// Variables
	AXI_VALUE inPixel;
	AXI_VALUE outPixel;

	static apuint19_t sum_Pixel;
	static apuint8_t n_Mean;
	static apuint14_t n_Var;
	static apuint8_t pixel[LENGTH];
	static apuint8_t tmp_Pixel[LENGTH];

	static ap_ufixed<12,8> w_gMean = brightness * g_Mean;
	static ap_ufixed<18,14> w_gVar = (1-contrast) * g_Var;
	static apuint10_t pos_Pixel = (LENGTH - 1) / 2;

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
									contrast, brightness, w_gMean, w_gVar);

	// ************************************************************************
	// Output
	outData.write(outPixel);


	// ************************************************************************
	// Loop
	// ************************************************************************
	loop_while:do {
		// ********************************************************************
		// Organize new Data

/*		loop_data:for(uint16_t i = 0; i < LENGTH; i++) {
			if(i < (LENGTH - WIN_SIZE)) {
				tmp_Pixel[i] = pixel[i+WIN_SIZE];
			}

			if(i < WIN_SIZE) {
				inPixel = inData.read();
				tmp_Pixel[i + (LENGTH - WIN_SIZE)] = inPixel.data;
				sum_Pixel -= pixel[i];
				sum_Pixel += tmp_Pixel[i + (LENGTH - WIN_SIZE)];
			}

			pixel[i] = tmp_Pixel[i];
		}*/

		// Old data delete
		loop_strData:for(uint16_t i = 0; i < (LENGTH - WIN_SIZE); i++) {
			tmp_Pixel[i] = pixel[i+WIN_SIZE];
		}

		// Add new data and calculate new mean
		loop_addData:for(uint16_t i = 0; (!inPixel.last) && (i < WIN_SIZE); i++) {
			inPixel = inData.read();
			tmp_Pixel[i + (LENGTH - WIN_SIZE)] = inPixel.data;

			sum_Pixel -= pixel[i];
			sum_Pixel += tmp_Pixel[i + (LENGTH - WIN_SIZE)];
		}

		// Set new data
		loop_setData:for(uint16_t i = 0; i < LENGTH; i++) {
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
		outPixel.data = Wallis_Filter(pixel[pos_Pixel], n_Mean, n_Var, g_Mean, g_Var,
										contrast, brightness, w_gMean, w_gVar);

		// ********************************************************************
		// Output
		outPixel.last = inPixel.last;
		outData.write(outPixel);
	}while(!inPixel.last);

}


/*
 * Calculate the mean
 */
apuint8_t Cal_Mean(apuint19_t sum_Pixel) {
	apuint8_t mean;

	mean = (sum_Pixel / LENGTH);

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
	
	loop_variance:for(uint16_t i = 0; i < LENGTH; i++) {
		tmp_Sub = (pixel[i] - mean);
		tmp_Pow = (tmp_Sub * tmp_Sub);
		sum_Pow = sum_Pow + tmp_Pow;
		//sum_Pow += (pixel[i] - mean) * (pixel[i] - mean);
	}

	var = (sum_Pow / (LENGTH - 1));

	return var;
}


/*
 * Calculate the Wallis Filter
 */
apuint8_t Wallis_Filter(apuint8_t v_pixel, apuint8_t n_Mean, apuint14_t n_Var,
						apuint8_t g_Mean, apuint14_t g_Var, ap_ufixed<5,1> contrast,
						ap_ufixed<5,1> brightness, ap_ufixed<12,8> w_gMean, ap_ufixed<18,14> w_gVar) {

	apint23_t tmp_Num;
	ap_fixed<27,23> fp_Num;
	ap_ufixed<18,14> fp_nVar;
	ap_ufixed<12,8> fp_nMean;
	ap_ufixed<19,15> fp_Var;
	ap_ufixed<20,5> fp_Den;
	ap_fixed<35,29> fp_Div;
	ap_ufixed<36,30, AP_RND, AP_SAT> w_Pixel;

	// int23 = (uint8 - uint8) * uint14
	tmp_Num = (v_pixel - n_Mean) * g_Var;
	// <27,23> = int23 * <5,1>
	fp_Num = tmp_Num * contrast;
	// <18,14> = <5,1> * uint14
	fp_nVar = contrast * n_Var;
	// <12,8> = (1 - <5,1>) * uint8
	fp_nMean = (1-brightness) * n_Mean;
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

/*apuint8_t Wallis_Filter(apuint8_t v_pixel, apuint8_t n_Mean, apuint35_t n_Var,
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

}*/



