/*
* @Author: Noah Huetter
* @Date:   2017-10-27 08:44:26
* @Last Modified by:   Noah Huetter
* @Last Modified time: 2017-12-01 11:55:48
*/


#include "ufp.h"
#include <printf.h>

int main(int argc, char const *argv[])
{
    printf("UFP Receiver demo\n");

    if(argc < 2)
    {
        printf("Usage: receiver filename\n");
        return 0;
    }

    // open file for sending
    FILE *fp = fopen( argv[1], "w" );
    if(fp == 0)
    {
        printf("Error: File not found\n");
        return -1;
    }   

    // send the file
    udf_receive_file(fp, 2222);
    fclose( fp );

    return 0;
}