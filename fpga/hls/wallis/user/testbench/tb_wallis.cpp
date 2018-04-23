//
//  tb_wallis.cpp
//
//  Created by Jan Stocker on 11.04.2018
//  Copyright © 2018 Jan Stocker. All rights reserved.
//

#include "../includes/wallis.h"

#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
using namespace cv;

#define INPUT_IMAGE "landscape.jpg"
#define G_MEAN 		127
#define G_VAR 		3600 // STD = 60
#define CONTRAST 	0.75	//0.75
#define BRIGHTNESS	0.2	//0.8

int main(int argc, const char * argv[]) {

	// ************************************************************************
	// Variables
	AXI_STREAM inDataFIFO;
	AXI_STREAM outData;
	AXI_VALUE inData;

	// Read Image
	Mat src_img = imread(INPUT_IMAGE);
	if (!src_img.data) {
		printf("***********************************************************\n");
		printf("	ERROR: could not open or find the input image!\n");
		printf("***********************************************************\n");
		return -1;
	}

	// Edit Image
	Mat src_gray;
	cvtColor(src_img, src_gray, CV_BGR2GRAY);
	uint16_t img_width = src_gray.cols;
	uint16_t img_length = src_gray.rows;
	uint16_t g_width = (img_width - WIN_SIZE + 1);
	uint16_t g_length = (img_length - WIN_SIZE + 1);


	// Puts data into FIFO
	int ctr = 0;
	uint16_t offset = 0;
	//for(uint16_t offset = 0; offset < g_length; offset++) {
		//for (uint16_t x = 0; x < img_width; x++) {
		for (uint16_t x = 0; x < WIN_SIZE; x++) {
			for (uint16_t y = 0; y < WIN_SIZE; y++) {
				inData.data = src_gray.at<apuint8_t>(Point(x, (y + offset)));
				inDataFIFO.write(inData);
			}
		}

		while(!inDataFIFO.empty()) {
			printf("ctr=%d\n",ctr++);
			wallis(inDataFIFO, outData, G_MEAN, G_VAR, CONTRAST, BRIGHTNESS, g_width);
		}
	//}


	// ************************************************************************
	// Output
	uint16_t dst_img_length = (img_length - WIN_SIZE + 1);
	uint16_t dst_img_width = (img_width - WIN_SIZE + 1);
	uint8_t w_data[dst_img_length * dst_img_width];
	uint32_t i = 0;
	
	while(!outData.empty()) {
		AXI_VALUE tmp = outData.read();
		w_data[i++] = (uint8_t)tmp.data;
		printf("Pixel = %d\n", (uint8_t)tmp.data);
		//printf("i=%d\n",i);
	}

	// Show image
/*	Mat dst_img = Mat(g_length, g_width, CV_8UC1, w_data);

	imwrite("wallis_landscape.jpg", dst_img);
	if (getenv("DISPLAY") != NULL)
	{
		imshow( "Original", src_gray );
		imshow( "Wallis", dst_img );
		waitKey(0);
	}*/


    return 0;
}
