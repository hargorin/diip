//
//  controller_tb.cpp
//
//  Created by Jan Stocker on 08/11/17.
//  Copyright © 2017 Jan Stocker. All rights reserved.
//
#include <stdlib.h>

#include "../inc/controller.h"


#define IN_SIZE 	(IMG_WIDTH*WINDOW_LEN)
#define OUT_SIZE 	(IMG_WIDTH-WINDOW_LEN+1)

#define RUN_DUV_N_TIMES(n) for(int duvrunctr=0; duvrunctr<(n); duvrunctr++) { \
	controller_top(memory, uft_reg, inData, outData, rx_done, &outState); \
}

int main()
{
	int i, err;

	// Connections to DUV
	uint8_t memory[IN_SIZE+OUT_SIZE];
    uint32_t uft_reg[16];
	AXI_STREAM outData;
	AXI_STREAM inData;

    ap_uint<1> rx_done = 0;
    ap_uint<4> outState = 0;



	uint8_t stream_set[IN_SIZE];
	uint8_t mem_set[IMG_WIDTH-WINDOW_LEN+1];


    uint32_t uft_reg_set[16];

    static AXI_VALUE aval;


	printf("***************\n");
	printf("Start Testbench\n");
	printf("Required memory size is %d bytes\n", IN_SIZE+OUT_SIZE);
	
	//************************************************************************
	//Put data into memory
	//************************************************************************
	uint8_t val = 0;
	for(i=0; i < (IN_SIZE); i++)
	{
		memory[i] = val++;
	}
	// Put data into stream comming from the core
	val = 255;
	for(i=0; i < (IMG_WIDTH-WINDOW_LEN+1); i++)
	{
		aval.data = val--;
		if(i == (IMG_WIDTH-WINDOW_LEN))
			aval.last = 1;
		inData.write(aval);
	}
	// clear out uft registers
	memset(uft_reg, 0, sizeof(uft_reg));

	//************************************************************************
	//Call the hardware function
	//************************************************************************
	RUN_DUV_N_TIMES(5)

	// Indicate enough Rx rows
	uft_reg[UFT_REG_RX_CTR] = WINDOW_LEN;
	uft_reg[UFT_REG_IMG_WIDTH] = IMG_WIDTH;
	rx_done = 1;
	RUN_DUV_N_TIMES(1)
	rx_done = 0;

	// Run for all Pixels
	RUN_DUV_N_TIMES(IN_SIZE+2)
//	RUN_DUV_N_TIMES(4)

	//************************************************************************
	//Run a software version of the hardware function to validate results
	//************************************************************************
	int row = 0;
	int col = 0;
	for(i=0; i < IN_SIZE; i++)
	{
		stream_set[i] = memory[row*IMG_WIDTH + col];
		row++;
		if(row == WINDOW_LEN)
		{
			row = 0;
			col++;
		}
	}
	// write the stream data to memory
	val = 255;
	for(i=0; i < (IMG_WIDTH-WINDOW_LEN+1); i++)
	{
		mem_set[i] = val--;
	}
	// uft_reg
	// memset(uft_reg_set, 0, sizeof(uft_reg_set));
	// uft_reg_set[0] = 0x1;
	// uft_reg_set[1] = 0x400;
	// uft_reg_set[2] = 0x1;
	// uft_reg_set[3] = 0x400;
	// uft_reg_set[4] = 0x1;
	// uft_reg_set[5] = 0x400;
	// uft_reg_set[6] = 0x1;
	// uft_reg_set[7] = 0x400;
	// uft_reg_set[8] = 0x1;
	// uft_reg_set[9] = 0x400;
	// uft_reg_set[10] = 0x1;
	// uft_reg_set[11] = 0x400;
	// uft_reg_set[12] = 0x1;
	// uft_reg_set[13] = 0x400;
	// uft_reg_set[14] = 0x1;
	// uft_reg_set[15] = 0x400;
	//************************************************************************
	//Compare results from output stream
	//************************************************************************
	err = 0;
	uint8_t test;
	bool oDatErr = false;
	for(i=0; i < IN_SIZE; i++)
	{
		aval = outData.read();
		test = (uint8_t)aval.data;
		if(stream_set[i] != test)
		{
			printf("ERROR[outData] HW and SW results mismatch\n");
			printf("ERROR[outData] i = %d B = %d out= %d\n",i,stream_set[i],test);
			err = -1; oDatErr = true;
		}
		// Assert TLAST signal
//		if(aval.last)
//			printf("i=%d last=1\n",i);
//		if(!aval.last)
//			printf("i=%d last=0\n",i);
		if (!aval.last && (i == (IN_SIZE-1)))
		{
			printf("ERROR[outData] TLAST was not asserted. i=%d of=%d\n",i,IN_SIZE);
			err = -1; oDatErr = true;
		}
		if (aval.last && (i != (IN_SIZE-1)))
		{
			printf("ERROR[outData] TLAST was asserted too early. i=%d of=%d\n",i,IN_SIZE);
			err = -1; oDatErr = true;
		}
	}
	if(!oDatErr)
	{
		printf("INFO[outData] HW and SW results match\n");
	}

	// Compare results from memory
	bool oMemErr = false;
	for(i=0; i < OUT_SIZE; i++)
	{
		if(memory[OUT_MEMORY_BASE+i] != mem_set[i])
		{
			printf("ERROR[memory] HW and SW results mismatch\n");
			printf("ERROR[memory] i = %d is = %d should= %d\n",i,memory[OUT_MEMORY_BASE+i],mem_set[i]);
			err = -1; oMemErr = true;
		}
	}
	if(!oMemErr)
	{
		printf("INFO[memory] HW and SW results match\n");
	}

	// Check UFT register
//	for(i = 0; i < 16; i++)
//	{
//		if(uft_reg[i] != uft_reg_set[i])
//		{
//			printf("Error: uft_reg[%d] is %x should %x\n", i, (uint32_t)uft_reg[0], (uint32_t)uft_reg_set[i]);
//			err = -1;
//		}
//	}

	if(err)
	{
		printf("Failed\n");
		printf("End Testbench\n");
		printf("***************\n");
		return err;
	}

	printf("Success! HW and SW results match\n");
	printf("End Testbench\n");
	printf("***************\n");
	return 0;
}

  
