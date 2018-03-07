//
//  test_sobel.cpp
//
//  Created by Jan Stocker on 08/11/17.
//  Copyright © 2017 Jan Stocker. All rights reserved.
//
#include <stdlib.h>

#include "../includes/sobel.h"

#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
using namespace cv;
#define INPUT_IMAGE "street512.tif"

int main(int argc, const char * argv[]) {

/*S
	// initialization
	uint64_t row0[block_width];
	uint64_t row1[block_width];
	uint64_t row2[block_width];
	uint64_t pixel[block_width-2];
	for(uint64_t i = 0; i < (block_width-1); i++) {
		row0[i] = 0x5d515555717d8a8e;
		row1[i] = 0x5d515555717d8a8e;
		row2[i] = 0x69615d79696d7d86;

		row0[i] = 0x8e8a7d715555515d;
		row0[i+1] = 0x716155616175D2B2;
		row1[i] = 0x8e8a7d715555515d;
		row1[i+1] = 0x716155616175D2B2;
		row2[i] = 0x867d6d69795d6169;
		row2[i+1] = 0x6d697d867982dbb2;
		i++;

		row0[i] = 0xE6FFB4FFDCFFC8FF;
		row1[i] = 0x0000000000000000;
		row2[i] = 0xFFFFFFFFFFFFFFFF;
	}


	sobel_abs(row0, row1, row2, pixel);

	printf("***********************************************************\n");
	printf("1-4 Pixel:  	0x%016lx\n", pixel[0]);
	printf("5-8 Pixel: 		0x%016lx\n", pixel[1]);
	printf("9-12 Pixel:	 	0x%016lx\n", pixel[2]);
	printf("13-16 Pixel:	0x%016lx\n", pixel[3]);
	printf("***********************************************************\n");*/






	// initialization
	uint64_t row0[block_width];
	uint64_t row1[block_width];
	uint64_t row2[block_width];
	uint64_t pixel[block_width-2];

	// read image
	Mat src_img = imread(INPUT_IMAGE);
	if (!src_img.data) {
		printf("***********************************************************\n");
		printf("	ERROR: could not open or find the input image!\n");
		printf("***********************************************************\n");
		return -1;
	}

	// edit image
	Mat src_gray, dst_img;
	cvtColor( src_img, src_gray, CV_BGR2GRAY );
	uint16_t img_width = src_gray.cols;
	uint16_t img_length = src_gray.rows;
	uint8_t img[img_length][img_width];

	uint16_t itr_row = 0;
	uint16_t N = 0;
	uint16_t x = 0;
	for(int y = 1; y <= (img_length - 2); y++) {
		x = 0;
		for(; x < (img_width-1);) {
			itr_row = 0;

			//
			if ( ! ((x + (block_width-2)) < (img_width - 1)) )
			{
				N = img_width - x;
			}
			else
			{
				N = block_width;
			}

			int itr_x = 0;
			uint64_t tmp_row0;
			uint64_t tmp_row1;
			uint64_t tmp_row2;
			while(itr_row < N) {
				tmp_row0 = 0;
				tmp_row1 = 0;
				tmp_row2 = 0;
				for(int shift = 0; shift < 8; shift++){
					tmp_row0 |= ( (uint64_t)src_gray.at<uchar>(Point(x+itr_x, y-1)) << (8*shift) );
					tmp_row1 |= ( (uint64_t)src_gray.at<uchar>(Point(x+itr_x, y)) << (8*shift) );
					tmp_row2 |= ( (uint64_t)src_gray.at<uchar>(Point(x+itr_x, y+1)) << (8*shift) );
					//printf("Row:  	0x%016lx\n", ( src_gray.at<uchar>(Point(x+d, y-1)) << (8*b) ));
					itr_x++;
				}

				row0[itr_row] = tmp_row0;
				row1[itr_row] = tmp_row1;
				row2[itr_row] = tmp_row2;

				itr_row++;
			}

			//Filter
			sobel_abs(row0, row1, row2, pixel);

			itr_row = 1;
			itr_x = 0;
			while(itr_row < (N - 1)) {
				for(int shift = 0; shift < 8; shift++) {
					img[y][x+itr_x] = (pixel[itr_row-1] >> (8*shift));
					itr_x++;
				}

				//printf("%d\n", img[y][x+itr_row]);
				itr_row++;
			}
			x = x + (block_width-2);
		}

	}

	// Output
	dst_img = Mat(img_length, img_width, CV_8UC1, img );

	printf("***********************************************************\n");
	printf("Width (x):  %d\n", img_width);
	printf("Length (y): %d\n", img_length);
	printf("***********************************************************\n");

	imwrite( "co_street512.tiff", dst_img );
	if (getenv("DISPLAY") != NULL)
	{
		imshow( "ABS", dst_img );
		waitKey(0);
	}

    return 0;
}
