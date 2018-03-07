//
//  main.cpp
//  image2file
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
    printf("image2file: Convert image to binary data for FPGA\n");
    printf("    usage: ./image2file input_file.tiff output_file.bin\n");
}

int main(int argc, const char * argv[]) {

    if(argc < 3)
    {
        printf("ERROR: not enough arguments\n");
        printUsage();
        return 2;
    }

    if(argc > 3)
    {
        printf("ERROR: too many arguments\n");
        printUsage();
        return 2;
    }
    const char * infile = argv[1];
    const char * outfile = argv[2];

    FILE* f = fopen(infile,"rb");
    FILE* f_data = fopen(outfile, "wb");
    
    if (!f) {
        printf("bad path : %s\n",infile);
        return -1;
    }

    Mat img = imread(infile, CV_8UC1);

    uint8_t data[img.cols * img.rows];

    uint32_t i = 0;
    for (int y = 0; y < img.rows; y++) {
        for (int x = 0; x < img.cols; x++) {
            data[i++] = img.at<uchar>(Point(x, y));
        }
    }

    fwrite (data , sizeof(uint8_t), img.cols * img.rows, f_data);

    fclose(f);
    fclose(f_data);
    
    return 0;
}
