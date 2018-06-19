//
//  main.cpp
//  file2image
//
//  Created by Jan Stocker on 30/11/17.
//  Copyright © 2017 Jan Stocker. All rights reserved.
//

#include <iostream>
#include <stdlib.h>
#include <stdio.h>
#include <cv.h>
#include <opencv2/highgui/highgui.hpp>

using namespace cv;
using namespace std;


// ****************************************************************************
// defines
#define G_MEAN      127     // Mean of the input image
#define G_VAR       3600    // Standard Deviation for the input image
#define CONTRAST    0.82    // Contrast expansion factor
#define BRIGHTNESS  0.49    // Brightness forcing factor

#define WIN_LENGTH  21  // Between 11 and 41 (depends on camera resolution)
#define WIN_SIZE    (WIN_LENGTH * WIN_LENGTH)


// ****************************************************************************
// Declerations
void printUsage ();


// ****************************************************************************
// Main
// ****************************************************************************
int main(int argc, const char * argv[]) {

    // ************************************************************************
    // Read input arguments
    if(argc < 3)
    {
        printf("ERROR: not enough arguments\n");
        printUsage();
        return 2;
    }

    if(argc > 4)
    {
        printf("ERROR: too many arguments\n");
        printUsage();
        return 2;
    }

    const char * infile = argv[1];
    const char * outfile = argv[2];


    // ************************************************************************
	// Read input image
    Mat src_img = imread(infile, IMREAD_GRAYSCALE);
    if (!src_img.data) {
        printf("***********************************************************\n");
        printf("    ERROR: could not open or find the input image!\n");
        printf("***********************************************************\n");
        return 1;
    }

    uint16_t img_width = src_img.cols;
    uint16_t img_height = src_img.rows;
    uint16_t g_height = (img_height - WIN_LENGTH + 1);
    uint16_t g_width = (img_width - WIN_LENGTH + 1);

    Mat w_img = Mat(g_height, g_width, CV_8UC1, Scalar(0));


    // ************************************************************************
    // Initialization
    // ************************************************************************
    static uint32_t sum_Pixel;
    static uint32_t sum_Pixel2;

    // Read data and calculate mean
    sum_Pixel = 0;
    sum_Pixel2 = 0;

    for(uint16_t y = 0; y < g_height; y++) {

        for(uint16_t i = 0; i < WIN_SIZE; i++) {
            sum_Pixel += src_img.at<uint8_t>(Point(y + i, (y + y_offset)));
            sum_Pixel2 += (src_img.at<uint8_t>(Point(x + x_offset, (y + y_offset))) * src_img.at<uint8_t>(Point(x + x_offset, (y + y_offset))));
            sum_Pixel2 += tmp_pow;
        }




       for(uint16_t x = 0; x < g_width; x++) {

        } 
    }





  

    





    // ************************************************************************
    // Show Image
    if (argc == 4 && strcmp(argv[3], "-s") == 0)
    {
        //imshow( "Original", img ); 
        imshow( "Wallis Filter", w_img );                   
        waitKey(0);  
    }

    return 0;
}


void printUsage () {
    printf("wallis_filter: Image content enhancement\n");
    printf("    usage: ./wallis_filter input_image output_image [-s]\n");
    printf("        input_image     Input image for content enhancement\n");
    printf("        output_image    Image file to write. Extension can be tiff, png, ...\n");
    printf("        -s              Show image\n");
    printf("                              \n");
    printf("    example: ./wallis_filter input_files/landscape.jpg wallis.jpg -s\n");
}


/*
 * Calculate the mean
 */
uint8_t Cal_Mean(uint32_t sum_Pixel) {
    uint32_t mean;

    mean = sum_Pixel / WIN_SIZE;

    return (uint8_t)mean;
}
