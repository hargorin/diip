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
#include <opencv2/imgproc.hpp>
#include <sys/time.h>

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
	const int ARR_LENGTH = 256;
	int hist[ARR_LENGTH] = {};
	long mean = 0;
	double pix_tile = 0.0;
	

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
    Mat img_clahe(img.rows, img.cols, CV_8UC1, Scalar(0));


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

    for (int i = 0; i < ARR_LENGTH; i++) {
    	printf("%d ", hist[i]);
    	sum += hist[i];
    }
    printf("\n");
    printf("SUM histogram: %ld\n", sum);
    sum = 0;

    // *********************************************************
    // Histogram clipping
    thr = mean * 12;
    int excess = 0;
    for (int i = 0; i < ARR_LENGTH; i++) {
    	if(hist[i] > thr) {
    		excess += hist[i] - thr;
    		hist[i] = thr;
    	}
    }


    for (int i = 0; i < ARR_LENGTH; i++) {
		printf("%d ", hist[i]);
		sum += hist[i];
    }
    printf("\n");
    printf("SUM (clipping): %ld\n", sum);
    printf("excess: %d\n", excess);
    sum = 0;

    // *********************************************************
    // Initial distribution
    int m = excess/ARR_LENGTH;
    for (int i = 0; i < ARR_LENGTH; i++) {
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


    for (int i = 0; i < ARR_LENGTH; i++) {
		printf("%d ", hist[i]);
		sum += hist[i];
    }
    printf("\n");
    printf("SUM (distribution): %ld\n", sum);
    printf("excess: %d\n", excess);
    sum = 0;

    // *********************************************************
    // Iterative redistribution of excess pixels
    while(excess > 0) {
    	for (int i = 0; i < ARR_LENGTH; i++) { 
    		if(excess > 0 ) {
    			if(hist[i] < thr) {
    				excess = excess - 1;
    				hist[i] = hist[i] + 1;
    			}
    		}
    	}
    }


    for (int i = 0; i < ARR_LENGTH; i++) {
		printf("%d ", hist[i]);
		sum += hist[i];
		pix_tile += hist[i];
    }
    printf("\n");
    printf("SUM (redistribution): %ld\n", sum);
    printf("excess: %d\n", excess);
    sum = 0;

    // *********************************************************
    // CDF calculation
    float cdf[ARR_LENGTH] = {};

    cdf[0] = hist[0] * ARR_LENGTH / pix_tile;
    for (int i = 1; i < ARR_LENGTH; i++) {
    	cdf[i] = cdf[i-1] + (hist[i] * ARR_LENGTH / pix_tile);
    }

    for (int i = 0; i < ARR_LENGTH; i++) {
		printf("%.2f ", cdf[i]);
		sum += cdf[i];
    }
    printf("\n");
    printf("SUM (CDF): %ld\n", sum);
    printf("excess: %d\n", excess);
    sum = 0;

    // *********************************************************
    // Remapping Pixels
    int hist_clahe[ARR_LENGTH] = {};

    for (int y = 0; y<img.rows; y++) {
        for (int x = 0; x < img.cols; x++) {
            img_clahe.at<uchar>(Point(x, y)) = cdf[img.at<uchar>(Point(x, y))];
            hist_clahe[img_clahe.at<uchar>(Point(x, y))] += 1;
        }
    }

    for (int i = 0; i < ARR_LENGTH; i++) {
		printf("%d ", hist_clahe[i]);
		sum += hist_clahe[i];
    }
    printf("\n");
    printf("SUM (CLAHE): %ld\n", sum);







/*    FILE* f_data0 = fopen(infile, "rb");
    buffer = (unsigned char*)malloc(sizeof(unsigned char)*filter_width*filter_height);
    result = fread(buffer, sizeof(unsigned char), filter_width*filter_height, f_data0);

    Mat img(filter_width, filter_height, CV_8UC1, buffer);
    fclose(f_data0);*/

    //imwrite( outfile, img);

    if (argc == 5 && strcmp(argv[4], "-s") == 0)
    {
        imshow( "Original Image", img );    
        imshow( "CLAHE Image", img_clahe );                 
        waitKey(0);  
    }
    return 0;
}




// *************************************************************
// Calculate the mean and standard deviation from an image
// *************************************************************


/*    Mat g_img;
    Mat img = imread(infile, CV_LOAD_IMAGE_COLOR);
    cvtColor(img, g_img, COLOR_RGB2GRAY);

    long start, end;
    struct timeval timecheck;

    gettimeofday(&timecheck, NULL);
    start = (long)timecheck.tv_sec * 1000 + (long)timecheck.tv_usec / 1000;


    
    for (int y = 0; y < g_img.rows; y++) {
        for (int x = 0; x < g_img.cols; x++) {
           	mean += g_img.at<uchar>(Point(x, y));
        }
    }


    gettimeofday(&timecheck, NULL);
    end = (long)timecheck.tv_sec * 1000 + (long)timecheck.tv_usec / 1000;

    printf("%ld milliseconds elapsed\n", (end - start));


    mean = mean / (g_img.rows * g_img.cols);
    printf("Mean: %ld\n", mean);



    gettimeofday(&timecheck, NULL);
    start = (long)timecheck.tv_sec * 1000 + (long)timecheck.tv_usec / 1000;

    long tmp;
    long var;
    
    for (int y = 0; y < g_img.rows; y++) {
        for (int x = 0; x < g_img.cols; x++) {
           	tmp = g_img.at<uchar>(Point(x, y));
           	var += pow((tmp - mean), 2);
        }
    }
    var = var / ((g_img.rows * g_img.cols) - 1);
    std = sqrt(var);


    gettimeofday(&timecheck, NULL);
    end = (long)timecheck.tv_sec * 1000 + (long)timecheck.tv_usec / 1000;

    printf("%ld milliseconds elapsed\n", (end - start));

    printf("STD: %ld\n", std);*/
