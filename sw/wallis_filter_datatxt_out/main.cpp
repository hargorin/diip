//
//  main.cpp
//  wallis_filter
//
//  Created by Jan Stocker on 30/11/17.
//  Copyright © 2017 Jan Stocker. All rights reserved.
//

#include <iostream>
#include <stdlib.h>
#include <stdio.h>
#include <sys/time.h>
#include <cv.h>
#include <opencv2/highgui/highgui.hpp>

using namespace cv;
using namespace std;


// ****************************************************************************
// defines
#define G_MEAN      127       // Mean of the input image
#define G_VAR       3600      // Standard Deviation for the input image
#define CONTRAST    0.8125    // Contrast expansion factor 0.82
#define BRIGHTNESS  0.484375  // Brightness forcing factor 0.49

#define WIN_LENGTH  21  // Between 11 and 41 (depends on camera resolution)
#define WIN_SIZE    (WIN_LENGTH * WIN_LENGTH)
#define WIN_LENGTH2 (WIN_LENGTH - 1) / 2

typedef struct tictocstruct
{
    struct timeval tv;
    double start;
    double end;
    FILE* fp;
    size_t bytes;
    float throughput;
} tictoc_t;


// ****************************************************************************
// Declerations
void printUsage ();
uint8_t Cal_Mean(uint32_t sum_Pixel);
uint16_t Cal_Variance(uint16_t mean2, uint32_t sum_pixel2);
uint8_t Wallis(uint8_t v_pixel, uint8_t n_mean, uint16_t n_var);
void tic(tictoc_t *tt);
void toc(tictoc_t *tt);


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
    //tictoc_t tt;

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
    //uint16_t img_width = 30;
    //uint16_t img_height = 30;
    uint16_t g_height = (img_height - WIN_LENGTH + 1);
    uint16_t g_width = (img_width - WIN_LENGTH + 1);


    // ************************************************************************
    // Initialization
    // ************************************************************************
    uint8_t n_Mean;
    uint16_t n_Var;
    uint32_t sum_Pixel = 0;
    uint32_t sum_Pixel2 = 0;
    uint8_t w_pixel;
    uint8_t *wallis = (uint8_t*)malloc((g_width * g_height) * sizeof(uint8_t));
    uint32_t index = 0;


    //tic(&tt);
    //for (int i = 0; i < 10000; i++) {
        index = 0;
        for(uint16_t y = 0; y < g_height; y++) {
            sum_Pixel = 0;
            sum_Pixel2 = 0;

            // ********************************************************************
            // Initialization WIN
            for(uint16_t x_win = 0; x_win < WIN_LENGTH; x_win++) {
                for(uint16_t y_win = 0; y_win < WIN_LENGTH; y_win++) {
                    printf("%02x\n",src_img.at<uint8_t>(Point(x_win, (y + y_win))));
                    sum_Pixel += src_img.at<uint8_t>(Point(x_win, (y + y_win)));
                    sum_Pixel2 += (src_img.at<uint8_t>(Point(x_win, (y + y_win))) * src_img.at<uint8_t>(Point(x_win, (y + y_win))));
                }
            }

            w_pixel = src_img.at<uint8_t>(Point(WIN_LENGTH2, (y + WIN_LENGTH2)));

            n_Mean = Cal_Mean(sum_Pixel);
            n_Var = Cal_Variance((n_Mean * n_Mean), sum_Pixel2);
            wallis[index] = Wallis(w_pixel, n_Mean, n_Var);
            


            // ********************************************************************
            // Calculate the whole width of the image
            for(uint16_t x = 0; x < (g_width - 1); x++) {

                // Substract old data, add new data
                for(uint16_t y_win = 0; y_win < WIN_LENGTH; y_win++) {
                    sum_Pixel -= src_img.at<uint8_t>(Point(x, (y + y_win)));
                    sum_Pixel2 -= (src_img.at<uint8_t>(Point(x, (y + y_win))) * src_img.at<uint8_t>(Point(x, (y + y_win))));

                    sum_Pixel += src_img.at<uint8_t>(Point((x + WIN_LENGTH), (y + y_win)));
                    sum_Pixel2 += (src_img.at<uint8_t>(Point((x + WIN_LENGTH), (y + y_win))) * src_img.at<uint8_t>(Point((x + WIN_LENGTH), (y + y_win))));
                    printf("%02x\n",src_img.at<uint8_t>(Point((x + WIN_LENGTH), (y + y_win))));
                }

                w_pixel = src_img.at<uint8_t>(Point((x + WIN_LENGTH2 + 1), (y + WIN_LENGTH2)));

                n_Mean = Cal_Mean(sum_Pixel);
                n_Var = Cal_Variance((n_Mean * n_Mean), sum_Pixel2);
                wallis[index] = Wallis(w_pixel, n_Mean, n_Var);
            }
        }
    //}
    //toc(&tt);

    Mat w_img = Mat(g_height, g_width, CV_8UC1, wallis);
    imwrite(outfile, w_img);

    // ************************************************************************
    // Show Image
    if (argc == 4 && strcmp(argv[3], "-s") == 0)
    {
        imshow("Original", src_img);
        imshow("Wallis Filter", w_img);                   
        waitKey(0);  
    }

    free(wallis);
    return 0;
}

/*
 * Print Usage
 */
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

/*
 * Calculate the variance
 */
uint16_t Cal_Variance(uint16_t mean2, uint32_t sum_pixel2) {
    uint32_t var;
    
    var = (sum_pixel2 / WIN_SIZE) - mean2;

    return (uint16_t)var;
}

/*
 * Calculate the Wallis Pixel
 */
uint8_t Wallis(uint8_t v_pixel, uint8_t n_mean, uint16_t n_var) {
    float w_Pixel;

    float dgb = ((v_pixel - n_mean) * CONTRAST * G_VAR) / (CONTRAST * n_var + (1 - CONTRAST) * G_VAR);
    w_Pixel = dgb + BRIGHTNESS * G_MEAN + (1 - BRIGHTNESS) * n_mean;

    if(w_Pixel > 255) w_Pixel = 255;
    if(w_Pixel < 0) w_Pixel = 0;

    return (uint8_t)w_Pixel;
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
