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

void printUsage () {
    printf("wallis_filter: Image content enhancement\n");
    printf("    usage: ./wallis_filter input_image output_image [-s]\n");
    printf("        input_image    	Input image for content enhancement\n");
    printf("        output_image   	Image file to write. Extension can be tiff, png, ...\n");
    printf("        -s          	Show image\n");
    printf("                              \n");
    printf("    example: ./wallis_filter input_files/landscape.jpg wallis.jpg -s\n");
}

int main(int argc, const char * argv[]) {

	// Declerations
    const int MEAN = 127;			// Mean of the input image
    const int STD = 60;			// Standard Deviation fo rthe input image
    const int CONTRAST = 0.8;		// Contrast expansion factor
    const int BRIGHTNESS = 1;		// Brigthness forcing factor


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



    // ************************************************************
    // Read input arguments
    const char * infile = argv[1];
    const char * outfile = argv[2];


	// Read input image
    Mat img = imread(infile, IMREAD_GRAYSCALE);
    int img_size = img.rows * img.cols;
  

    int loc_mean = 0;
    int loc_std = 0;


    // ************************************************************
    // Calculate local mean
    for (int y = 0; y < img.rows; y++) {
        for (int x = 0; x < img.cols; x++) {
           	loc_mean += img.at<uchar>(Point(x, y));
        }
    }

    loc_mean = loc_mean / img_size;



    // ************************************************************
    // Calculate local standard deviation
    int tmp = 0;
    long var = 0;
    
    for (int y = 0; y < img.rows; y++) {
        for (int x = 0; x < img.cols; x++) {
           	tmp = img.at<uchar>(Point(x, y));
           	var += pow((tmp - loc_mean), 2);
        }
    }
    var = var / (img_size - 1);
    loc_std = sqrt(var);



    // ************************************************************
    // Wallis filtering
    Mat w_img(img.rows, img.cols, CV_8UC1, Scalar(0));

    for (int y = 0; y < img.rows; y++) {
        for (int x = 0; x < img.cols; x++) {
        	tmp = STD * (img.at<uchar>(Point(x, y)) - loc_mean);
        	tmp = tmp / (loc_std + CONTRAST);
        	tmp = tmp + (MEAN * BRIGHTNESS);
        	tmp = tmp + (loc_mean * (1 - BRIGHTNESS));
        	w_img.at<uchar>(Point(x, y)) = tmp;
        }
    }




    // Output
    if (argc == 4 && strcmp(argv[3], "-s") == 0)
    {
        imshow( "Original", img ); 
        imshow( "Wallis Filter", w_img );                   
        waitKey(0);  
    }
    return 0;
}
