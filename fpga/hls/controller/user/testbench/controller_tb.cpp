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
	int A[50];
	int B[50];

	printf("***************\n");
	printf("Start Testbench\n");
	
	//Put data into A
	for(i=0; i < 50; i++)
	{
		A[i] = i;
	}

	//Call the hardware function
	controller_top(A);

	//Run a software version of the hardware function to validate results
	for(i=0; i < 50; i++)
	{
		B[i] = i + 100;
	}

	//Compare results
	for(i=0; i < 50; i++)
	{
		if(B[i] != A[i])
		{
			printf("i = %d A = %d B= %d\n",i,A[i],B[i]);
			printf("ERROR HW and SW results mismatch\n");
			return 1;
		}
	}
	printf("Success HW and SW results match\n");
	printf("\n\nEnd Testbench\n");
	printf("***************\n");
	return 0;
}

  