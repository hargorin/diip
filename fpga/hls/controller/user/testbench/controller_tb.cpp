//
//  controller_tb.cpp
//
//  Created by Jan Stocker on 08/11/17.
//  Copyright © 2017 Jan Stocker. All rights reserved.
//
#include <stdlib.h>

#include "../includes/controller.h"

int main()
{
	int i;
	int memory[IN_SIZE+OUT_SIZE];
	int B[WINDOW_HEIGHT*LINE_SIZE];
	int mem_set[LINE_SIZE-WINDOW_HEIGHT+1];


    AXI_VALUE aval;
	AXI_STREAM outData;
	AXI_STREAM inData;


	printf("***************\n");
	printf("Start Testbench\n");
	printf("Required memory size is %d bytes\n", IN_SIZE+OUT_SIZE);
	
	//Put data into memory
	uint8_t val = 0;
	for(i=0; i < (WINDOW_HEIGHT*LINE_SIZE); i++)
	{
		memory[i] = val++;
	}
	// Put data into stream comming from the core
	val = 255;
	for(i=0; i < (LINE_SIZE-WINDOW_HEIGHT+1); i++)
	{
		aval.data = val--;
		if(i == (LINE_SIZE-WINDOW_HEIGHT))
			aval.last = 1;
		inData.write(aval);
	}

	//Call the hardware function
	controller_top(memory, outData, inData);

	//Run a software version of the hardware function to validate results
	int row = 0;
	int col = 0;
	for(i=0; i < WINDOW_HEIGHT*LINE_SIZE; i++)
	{
		B[i] = memory[row*LINE_SIZE + col];
		row++;
		if(row == WINDOW_HEIGHT)
		{
			row = 0;
			col++;
		}
	}
	// write the stream data to memory
	val = 255;
	for(i=0; i < (LINE_SIZE-WINDOW_HEIGHT+1); i++)
	{
		mem_set[i] = val--;
	}

	//Compare results from output stream
	uint8_t test;
	for(i=0; i < WINDOW_HEIGHT*LINE_SIZE; i++)
	{
		test = (uint8_t)outData.read().data;
//		printf("i = %d outData = %d\n",i,(uint8_t)outData.read().data);
		if(B[i] != test)
		{
			printf("i = %d B = %d out= %d\n",i,B[i],test);
			printf("ERROR HW and SW results mismatch\n");
			return 1;
		}
	}

	//Compare results from memory
	for(i=0; i < (LINE_SIZE-WINDOW_HEIGHT+1); i++)
	{
		if(memory[OUT_MEMORY_BASE+i] != mem_set[i])
		{
			printf("i = %d is = %d should= %d\n",i,memory[OUT_MEMORY_BASE+i],mem_set[i]);
			printf("ERROR HW and SW results mismatch\n");
			return 1;
		}
	}

	printf("Success! HW and SW results match\n");
	printf("End Testbench\n");
	printf("***************\n");
	return 0;
}

  
