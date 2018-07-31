//
//  main.cpp
//  file2image
//
//  Created by Jan Stocker on 22/06/18.
//  Copyright © 2018 Jan Stocker. All rights reserved.
//

#include <iostream>
#include <stdlib.h>
#include <stdio.h>
#include <cv.h>
#include <opencv2/highgui/highgui.hpp>

using namespace cv;
using namespace std;

void printUsage () {
    printf("file2image: Convert binary data from FPGA to an image\n");
    printf("    usage: ./file2image input_file.bin output_file.tiff width height [-s]\n");
    printf("        input_file.bin     Input file from FPGA\n");
    printf("        output_file.tiff   Image file to write. Extension can be tiff, png, ...\n");
    printf("        width              Input file image width\n");
    printf("        height             Input file image height\n");
    printf("        -s                 Show image\n");
    printf("                              \n");
    printf("    example: ./file2image input_files/bridge_sobel.bin out.png 510 510 -s\n");
}

int main(int argc, const char * argv[]) {
    uint8_t* buffer;
    size_t result;

    if(argc < 5)
    {
        printf("ERROR: not enough arguments\n");
        printUsage();
        return 2;
    }

    if(argc > 6)
    {
        printf("ERROR: too many arguments\n");
        printUsage();
        return 2;
    }
    // Read input arguments
    const char * infile = argv[1];
    const char * outfile = argv[2];
    char * pEnd;

    int filter_width = strtol(argv[3], &pEnd, 10);
    int filter_height = strtol(argv[4], &pEnd, 10);
    buffer = (uint8_t*)malloc(sizeof(uint8_t)*filter_width*filter_height);

    // Filter-Image
    FILE* f_data = fopen(infile, "rb");
    fseek(f_data, 0, SEEK_SET);
    result = fread(buffer, sizeof(uint8_t), filter_width*filter_height, f_data);

    Mat img(filter_height, filter_width, CV_8UC1, buffer);
    fclose(f_data);

    imwrite(outfile, img);
    if (argc == 6 && strcmp(argv[5], "-s") == 0)
    {
        imshow(outfile, img);                   
        waitKey(0);  
    }
    return 0;
}
