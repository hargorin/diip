//
//  stream_dummy_tb.cpp
//
//  Created by Jan Stocker on 08/11/17.
//  Copyright © 2017 Jan Stocker. All rights reserved.
//
#include <stdlib.h>

#include "../includes/stream_dummy.h"

int main()
{
	int i;
	int mem_set[LINE_SIZE-WINDOW_HEIGHT+1];


    AXI_VALUE aval;
	AXI_STREAM outData;
	AXI_STREAM inData;


	printf("***************\n");
	printf("Start Testbench\n");
	
	// Put data into stream comming from the core
	uint8_t val = 0;
	for(i=0; i < (LINE_SIZE-WINDOW_HEIGHT+1); i++)
	{
		aval.data = val++;
		inData.write(aval);
	}

	//Call the hardware function
	stream_dummy_top(inData, outData);

	// write the stream data to memory
	val = 0;
	for(i=0; i < (LINE_SIZE-WINDOW_HEIGHT+1); i++)
	{
		mem_set[i] = (uint8_t)(val + 2);
		val++;
	}

	//Compare results from memory
	uint8_t test;
	for(i=0; i < (LINE_SIZE-WINDOW_HEIGHT+1); i++)
	{
		test = (uint8_t)outData.read().data;
		if(test != mem_set[i])
		{
			printf("i = %d is = %d should= %d\n",i,test,mem_set[i]);
			printf("ERROR HW and SW results mismatch\n");
			return 1;
		}
	}

	printf("Success! HW and SW results match\n");
	printf("End Testbench\n");
	printf("***************\n");
	return 0;
}

  
