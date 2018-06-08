//
//  tb_clahe.cpp
//
//  Created by Jan Stocker on 11.04.2018
//  Copyright © 2018 Jan Stocker. All rights reserved.
//

#include "../includes/clahe.h"

#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
using namespace cv;


int main(int argc, const char * argv[]) {

	// ************************************************************************
	// Defines
	AXI_STREAM inDataFIFO0, inDataFIFO1, inDataFIFO2, inDataFIFO3;
	AXI_STREAM outData0, outData1, outData2, outData3;
	AXI_VALUE inData;

	inData.data = 211;

	for(int i = 0; i < (BLOCK_SIZE * BLOCK_SIZE); i++) {
		inDataFIFO0.write(inData);
		inDataFIFO1.write(inData);
		inDataFIFO2.write(inData);
		inDataFIFO3.write(inData);
	}

	int ctr = 0;
	while(!inDataFIFO3.empty()) {
		printf("ctr=%d\n",ctr++);
		clahe(inDataFIFO0, inDataFIFO1, inDataFIFO2, inDataFIFO3,
				outData0, outData1, outData2, outData3);
	}


	while(!outData3.empty()) {
		AXI_VALUE tmp = outData0.read();
		tmp = outData1.read();
		tmp = outData2.read();
		tmp = outData3.read();
		printf("%d\n", (uint16_t)tmp.data);
	}


    return 0;
}
