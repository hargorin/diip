//
//  main.cpp
//  clahe
//
//  Created by Jan Stocker on 14/03/18.
//  Copyright © 2017 Jan Stocker. All rights reserved.
//

#include <iostream>
#include <stdlib.h>
#include <stdio.h>
#include <cv.h>
#include <opencv2/highgui/highgui.hpp>

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

int main(int argc, const char * argv[]) {
	int arr_length = 256;
	int hist[arr_length] = {};
	long mean = 0;

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
    int thr = strtol(argv[3], &pEnd, 10);


    // Read input image
    Mat img = imread(infile, IMREAD_GRAYSCALE);


    // *********************************************************
    // Calculate the histogram
    int intensity = 0;
    long sum = 0;
    for (int y = 0; y < img.rows; y++) {
        for (int x = 0; x < img.cols; x++) {
            intensity = img.at<uchar>(Point(x, y));
            hist[intensity] += 1;
            mean += intensity;
        }
    }

    mean = mean / (img.rows * img.cols);	// mean value
    printf("mean: %ld\n", mean);

    for (int i = 0; i < arr_length; ++i) {
    	printf("%d ", hist[i]);
    	sum += hist[i];
    }
    printf("\n");
    printf("SUM histogram: %ld\n", sum);
    sum = 0;

    // *********************************************************
    // Histogram clipping
    thr = mean * 4;
    int excess = 0;
    for (int i = 0; i < arr_length; ++i) {
    	if(hist[i] > thr) {
    		excess += hist[i] - thr;
    		hist[i] = thr;
    	}
    }


    for (int i = 0; i < arr_length; ++i) {
		printf("%d ", hist[i]);
		sum += hist[i];
    }
    printf("\n");
    printf("SUM (clipping): %ld\n", sum);
    printf("excess: %d\n", excess);

    // *********************************************************
    // Initial distribution
    int m = excess/arr_length;
    for (int i = 0; i < arr_length; ++i) {
    	if(excess > 0) {
    		if(hist[i] < (thr - m)) {
    			hist[i] = hist[i] + m; 
    			excess -= m;
    		}
    		else if(hist[i] < thr) {
    			hist[i] = thr;
    			excess = excess - thr + hist[i];
    		}
    	}
    }


    for (int i = 0; i < arr_length; ++i) {
		printf("%d ", hist[i]);
		sum += hist[i];
    }
    printf("\n");
    printf("SUM (distribution): %ld\n", sum);
    printf("excess: %d\n", excess);

    // *********************************************************
    // Iterative redistribution of excess pixels
    while(excess > 0) {
    	for (int i = 0; i < arr_length; ++i) { 
    		if(excess > 0 ) {
    			if(hist[i] < thr) {
    				excess = excess - 1;
    				hist[i] = hist[i] + 1;
    			}
    		}
    	}
    }


    for (int i = 0; i < arr_length; ++i) {
		printf("%d ", hist[i]);
		sum += hist[i];
    }
    printf("\n");
    printf("SUM (redistribution): %ld\n", sum);
    printf("excess: %d\n", excess);








/*    FILE* f_data0 = fopen(infile, "rb");
    buffer = (unsigned char*)malloc(sizeof(unsigned char)*filter_width*filter_height);
    result = fread(buffer, sizeof(unsigned char), filter_width*filter_height, f_data0);

    Mat img(filter_width, filter_height, CV_8UC1, buffer);
    fclose(f_data0);*/

    //imwrite( outfile, img);

    if (argc == 5 && strcmp(argv[4], "-s") == 0)
    {
        imshow( "Original Image", img );                   
        waitKey(0);  
    }
    return 0;
}
