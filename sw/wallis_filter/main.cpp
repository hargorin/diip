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
    const int STD = 60;				// Standard Deviation for the input image
    const float CONTRAST = 1.6;		// Contrast expansion factor
    const float BRIGHTNESS = 0.6;		// Brightness forcing factor

    const int LOC_LENGTH = 25;
    const int LOC_WIDTH = 25;


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
    Mat w_img(img.rows, img.cols, CV_8UC1, Scalar(0));
    int img_size = img.rows * img.cols;
  

    int loc_mean = 0;
    int loc_std = 0;

    int mean_y = 0;
    int std_y = 0;
    int wal_y = 0;
    int loop_y = 0;
    int loop_x = 0;
    int mean_x = 0;

    for(int i = 0; i < img.rows; ) {
    	loop_x = 0;

		if((i + LOC_WIDTH) >= img.rows) {
			loop_y += img.rows - i; 
		}
		else {
			loop_y += LOC_WIDTH;
		}

    	for (int j = 0; j < img.cols; ) {
    		mean_y = i;
    		std_y = i;
    		wal_y = i;

    		if((j + LOC_LENGTH) >= img.cols) {
    			loop_x += img.cols - j; 
    		}
    		else {
    			loop_x += LOC_LENGTH;
    		}


		    // ************************************************************
		    // Calculate local mean
		    for (; mean_y < loop_y; mean_y++) {
		        for (mean_x = j; mean_x < loop_x; mean_x++) {
		           	loc_mean += img.at<uchar>(Point(mean_x, mean_y));
		        }
		    }
		    loc_mean = loc_mean / img_size;



		    // ************************************************************
		    // Calculate local standard deviation
		    float tmp = 0;
		    double var = 0;
		    
		    for (; std_y < loop_y; std_y++) {
		        for (int std_x = j; std_x < loop_x; std_x++) {
		           	tmp = img.at<uchar>(Point(std_x, std_y));
		           	var += pow((tmp - loc_mean), 2);
		        }
		    }
		    var = var / (img_size - 1);
		    loc_std = sqrt(var);



		    // ************************************************************
		    // Wallis filtering
		    tmp = 0;

		    for (; wal_y < loop_y; wal_y++) {
		        for (int wal_x = j; wal_x < loop_x; wal_x++) {
		        	tmp = STD * (img.at<uchar>(Point(wal_x, wal_y)) - loc_mean);
		        	tmp = tmp / (loc_std + CONTRAST);
		        	tmp = tmp + (MEAN * BRIGHTNESS);
		        	tmp = tmp + (loc_mean * (1 - BRIGHTNESS));
		        	w_img.at<uchar>(Point(wal_x, wal_y)) = tmp;
		        }
		    }
    		



    		j += LOC_LENGTH;
    	}
    	i += LOC_WIDTH;
    }





    // Output
    if (argc == 4 && strcmp(argv[3], "-s") == 0)
    {
        //imshow( "Original", img ); 
        imshow( "Wallis Filter", w_img );                   
        waitKey(0);  
    }
    return 0;
}
