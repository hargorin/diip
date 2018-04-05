//
//  main.cpp
//  clahe
//
//  Created by Jan Stocker on 14/03/18.
//  Copyright © 2017 Jan Stocker. All rights reserved.
//

#include <stdint.h>
#include <iostream>
#include <fstream>
#include <stdlib.h>
#include <stdio.h>
#include <cv.h>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc.hpp>

using namespace cv;
using namespace std;

void printUsage () {
    printf("clahe: Contrast Limited Adaptive Histogram Equalization\n");
    printf("    usage: ./clahe input_image output_image clipping_value [-s]\n");
    printf("        input_image     	Input image for local contrast enhancement\n");
    printf("        output_image   		Output image \n");
    printf("        clipping_value		Threshold for for histogram clipping\n");
    printf("        -s                 	Show image\n");
    printf("                              \n");
    printf("    example: ./clahe input_files/landscape.jpg clahe_landscape.jpg 32 -s\n");
}


// ****************************************************************************
// Declares
#define WIN_SIZE 	4
#define BLOCK_SIZE 	64
#define NUM_BINS 	256


// ****************************************************************************
// MAIN
// ****************************************************************************
int main(int argc, const char * argv[]) {

	// ************************************************************************
	// Defines
	typedef uint16_t Hist_t[NUM_BINS] ;
	typedef uint8_t Cdf_t[NUM_BINS] ;

	typedef struct Window {
		Cdf_t cdf;
		Hist_t hist;
	} Window_t;

	Window_t win[WIN_SIZE * WIN_SIZE];
	Cdf_t cdf_store[WIN_SIZE] = {}; // CDF Storage for the next iteration

	uint16_t excess = 0;
	uint16_t fullbin = 0;
	double num_pixel = 0.0;


	// ************************************************************************
	// Console Input
	FILE *fp;

    if(argc < 4)
    {
        printf("ERROR: not enough arguments\n");
        printUsage();
        return 2;
    }

    if(argc > 5)
    {
        printf("ERROR: too many arguments\n");
        printUsage();
        return 2;
    }

    // Read input arguments
    const char * infile = argv[1];
    const char * outfile = argv[2];
    char * pEnd;
    uint8_t thr = strtol(argv[3], &pEnd, 10);


    // Read input image
    Mat img = imread(infile, IMREAD_GRAYSCALE);
    Mat img_clahe(img.rows, img.cols, CV_8UC1, Scalar(0));


	// ************************************************************************
	// Iteration throught Image
	// ************************************************************************
   	uint16_t x_tmp = 0;
   	uint16_t x_win = 0;
	uint16_t y_img = 0;
	uint8_t intensity = 0;


		// ********************************************************************
		// Iteration throught Window
	    for (uint8_t win_itr = 0; win_itr < (WIN_SIZE * WIN_SIZE); win_itr++) {
	    	excess = 0;

	    	// ****************************************************************
	    	// Calculate Histogram
	    	for (; y_img < BLOCK_SIZE; y_img++) {
		        for (uint16_t x_img = x_tmp; x_img < (x_tmp + BLOCK_SIZE); x_img++) {
		            intensity = img.at<uchar>(Point(x_img, y_img));
		            win[win_itr].hist[intensity] += 1;
		        }
	    	}

	    	// *********************************************************
		    // Histogram clipping
		    for (uint8_t i = 0; i < NUM_BINS; i++) {
		    	if(win[win_itr].hist[i] > thr) {
		    		excess += win[win_itr].hist[i] - thr;
		    		win[win_itr].hist[i] = thr;
		    	}
		    }

		    // *********************************************************
		    // Initial distribution
		    uint16_t m = excess/NUM_BINS;
		    for (uint8_t i = 0; i < NUM_BINS; i++) {
		    	if(excess > 0) {
		    		if(win[win_itr].hist[i] < (thr - m)) {
		    			win[win_itr].hist[i] = win[win_itr].hist[i] + m; 
		    			excess -= m;
		    		}
		    		else if(win[win_itr].hist[i] < thr) {
		    			win[win_itr].hist[i] = thr;
		    			//excess = excess - thr + win[win_itr].hist[i];
		    		}
		    	}
		    }

		    // *********************************************************
		    // Iterative redistribution of excess pixels
		    while(excess > 0) {
		    	for (uint8_t i = 0; i < NUM_BINS; i++) { 
		    		if(excess > 0) {
		    			if(win[win_itr].hist[i] < thr) {
		    				excess = excess - 1;
		    				win[win_itr].hist[i] = win[win_itr].hist[i] + 1;
		    			}
		    		}
		    	}
		    }

		    for (uint8_t i = 0; i < NUM_BINS; i++) {
				num_pixel += win[win_itr].hist[i];
		    }

	        // *********************************************************
    		// CDF calculation
    		win[win_itr].cdf[0] = win[win_itr].hist[0] * NUM_BINS / num_pixel;
    		for (uint8_t i = 1; i < NUM_BINS; i++) {
    			win[win_itr].cdf[i] = win[win_itr].cdf[i-1] + (win[win_itr].hist[i] * NUM_BINS / num_pixel);
    		}






	    	if( ((win_itr+1) % WIN_SIZE) == 0 ) {
	    		x_tmp = x_win;
	    	}
	    	else {
	    		x_tmp += BLOCK_SIZE;
	    	}
	    }

	    x_win += WIN_SIZE;




  	// ************************************************************************
	// Output and show Image
    if (argc == 5 && strcmp(argv[4], "-s") == 0) {
        imshow( "Original Image", img );    
        imshow( "CLAHE Image", img_clahe );                 
        waitKey(0);  
    }
    return 0;
}

