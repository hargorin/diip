//
//  main.cpp
//
//  Created by Jan Stocker on 30/11/17.
//  Copyright © 2017 Jan Stocker. All rights reserved.
//

#include <iostream>
#include <stdlib.h>
#include <stdio.h>
#include <sys/time.h>

#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>

using namespace cv;
using namespace std;

typedef struct tictocstruct
{
    struct timeval tv;
    double start;
    double end;
    FILE* fp;
    size_t bytes;
    float throughput;
} tictoc_t;

#define WIN_LENGTH 21
#define WIN_SIZE (WIN_LENGTH * WIN_LENGTH)

uint8_t C_Mean(uint8_t *pixel);
uint16_t C_Var(uint8_t *pixel, uint8_t mean);
void tic(tictoc_t *tt);
void toc(tictoc_t *tt);




void printUsage () {
    printf("mean_var: Calculate mean and variance of a nightboorhood from an image\n");
    printf("    usage: ./mean_var input_image\n");
    printf("        input_image    	Input image for calculation\n");
    printf("                              \n");
    printf("    example: ./mean_var input_files/landscape.jpg\n");
}

int main(int argc, const char * argv[]) {

    tictoc_t tt;

    if(argc < 1)
    {
        printf("ERROR: not enough arguments\n");
        printUsage();
        return 2;
    }

    if(argc > 2)
    {
        printf("ERROR: too many arguments\n");
        printUsage();
        return 2;
    }


    // ************************************************************
    // Read input arguments
    const char * infile = argv[1];


	// Read input image
    Mat src_img = imread(infile);
    Mat src_gray;
    cvtColor(src_img, src_gray, CV_BGR2GRAY);
   	
   	uint16_t img_width = src_gray.cols;
	uint16_t img_height = src_gray.rows;
	uint16_t g_height = (img_height - WIN_LENGTH + 1);
	uint16_t g_width = (img_width - WIN_LENGTH + 1);

	uint8_t* c_mean = (uint8_t*)malloc((g_width * g_height) * sizeof(uint8_t));
	uint16_t* c_var = (uint16_t*)malloc((g_width * g_height) * sizeof(uint16_t));
	uint8_t c_pixel[WIN_SIZE];

	uint32_t index = 0;
	tic(&tt);
	for(uint16_t y_offset = 0; y_offset < g_height; y_offset++) {
		for(uint16_t x_offset = 0; x_offset < g_width; x_offset++) {
			uint16_t i_pixel = 0;
			for (uint8_t x = 0; x < WIN_LENGTH; x++) {
				for (uint8_t y = 0; y < WIN_LENGTH; y++) {
					c_pixel[i_pixel++] = src_gray.at<uint8_t>(Point(x + x_offset, (y + y_offset)));
				}
			}
			c_mean[index] = C_Mean(c_pixel);
			c_var[index] = C_Var(c_pixel, c_mean[index]);
			index++;
		}
	}
	toc(&tt);


    // Output
/*	for(uint32_t i = 0; i < (index-1); i++) {
		printf("%d - %d\n", c_mean[i], c_var[i]);
	}*/


    return 0;
}



uint8_t C_Mean(uint8_t *pixel) {
	uint32_t c_sumPixel = 0;
	uint8_t mean = 0;

	for(uint16_t k = 0; k < WIN_SIZE; k++) {
		c_sumPixel += pixel[k];
	}

	mean = c_sumPixel / WIN_SIZE;
	return mean;
}

uint16_t C_Var(uint8_t *pixel, uint8_t mean) {
	uint32_t c_sumPow = 0;
	uint16_t var = 0;

	for(uint16_t k = 0; k < WIN_SIZE; k++) {
		c_sumPow += (pixel[k] - mean) * (pixel[k] - mean);
	}

	var = c_sumPow / (WIN_SIZE);
	return var;
}


/**
 * @brief      Start time measurement
 *
 * @param      tt    tictoc_t structure
 */
void tic(tictoc_t *tt)
{
    gettimeofday(&tt->tv,NULL);
    tt->start = 1000000 * tt->tv.tv_sec + tt->tv.tv_usec;
}

/**
 * @brief      Stop time measurement and report elapsed, speed and filesize
 *
 * @param      tt    tictoc_t structure
 */
void toc(tictoc_t *tt)
{
    gettimeofday(&tt->tv,NULL);
    tt->end = 1000000 * tt->tv.tv_sec + tt->tv.tv_usec;
    if(tt->fp)
    {
        // tt->bytes = get_filesize_bytes(tt->fp);
    }
    tt->throughput = 1.0*(tt->bytes) / ((tt->end-tt->start) / 1000000.0);
    printf( "time elapsed: %.0fus Speed: %.3f MB/s Size: %.3f MB\n", 
        (tt->end-tt->start),  
        tt->throughput / 1024.0 / 1024.0,
        tt->bytes/1024.0/1024.0);
}

