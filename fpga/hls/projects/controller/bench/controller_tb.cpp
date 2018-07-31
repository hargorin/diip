//
//  controller_tb.cpp
//
//  Created by Jan Stocker on 08/11/17.
//  Copyright © 2017 Jan Stocker. All rights reserved.
//
#include <stdlib.h>
#include <time.h>

#include "../inc/controller.h"


#define IN_SIZE 	(IMG_WIDTH*WINDOW_LEN)
#define OUT_SIZE 	(IMG_WIDTH-WINDOW_LEN+1)

#define RUN_DUV_N_TIMES(n) for(int duvrunctr=0; duvrunctr<(n); duvrunctr++) { \
	controller_top(memory, uft_reg, inData, outData, rx_done, tx_ready, &outState); \
}

int main()
{
	int i, err;

	// Connections to DUV
	uint8_t memory[IN_SIZE+OUT_SIZE];
    uint32_t uft_reg[16];
	AXI_STREAM outData;
	AXI_STREAM inData;
	uint8_t inDataValidate[OUT_SIZE];

    ap_uint<1> rx_done = 0;
    ap_uint<1> tx_ready = 0;
    ap_uint<4> outState = 0;



	uint8_t stream_set[IN_SIZE];
	uint8_t mem_set[OUT_SIZE];


    uint32_t uft_reg_set[16];

    static AXI_VALUE aval;


	printf("***************\n");
	printf("Start Testbench\n");
	printf("Required memory size is %d bytes\n", IN_SIZE+OUT_SIZE);
	srand (time(NULL));

	//************************************************************************
	//Put data into memory
	//************************************************************************
	uint8_t val = 0;
	for(i=0; i < (IN_SIZE); i++)
	{
		memory[i] = rand() % 256;
	}
	// Put data into stream comming from the core
	for(i=0; i < (OUT_SIZE); i++)
	{
		inDataValidate[i] = rand() % 256;
		aval.data = inDataValidate[i];
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
	RUN_DUV_N_TIMES(IN_SIZE+4)

	// indicate ready
	uft_reg[UFT_REG_STATUS] = UFT_REG_STATUS_TX_READY;
	tx_ready = 1;
	RUN_DUV_N_TIMES(2)

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
	for(i=0; i < (OUT_SIZE); i++)
	{
		mem_set[i] = inDataValidate[i];
	}
	// uft_reg
	 memset(uft_reg_set, 0, sizeof(uft_reg_set));
	 uft_reg_set[UFT_REG_STATUS] = UFT_REG_STATUS_TX_READY;
	 uft_reg_set[UFT_REG_RX_CTR] = WINDOW_LEN;
	 uft_reg_set[UFT_REG_IMG_WIDTH] = IMG_WIDTH;
	 uft_reg_set[UFT_REG_CONTROL] = UFT_REG_CONTROL_TX_START;
	 uft_reg_set[UFT_REG_TX_BASE] = OUT_MEMORY_BASE;
	 uft_reg_set[UFT_REG_TX_SIZE] = OUT_SIZE;
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
	for(i = 0; i < 16; i++)
	{
		if(uft_reg[i] != uft_reg_set[i])
		{
			printf("ERROR[uft_reg]: uft_reg[%d] is %04x should %04x\n", i, (uint32_t)uft_reg[0], (uint32_t)uft_reg_set[i]);
			err = -1;
		}
	}

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

  
