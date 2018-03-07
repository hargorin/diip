/*
* @Author: Noah Huetter
* @Date:   2017-10-27 08:44:26
* @Last Modified by:   Noah Huetter
* @Last Modified time: 2017-11-15 18:22:52
*/


#include "ufp.h"
#include <printf.h>

int main(int argc, char const *argv[])
{
    printf("UFP Sender demo\n");

    if(argc < 3)
    {
        printf("Usage: ./sender IP filename\n");
        return 0;
    }

    // open file for sending
    FILE *fp = fopen( argv[2], "r" );
    if(fp == 0)
    {
        printf("Error: File not found\n");
        return -1;
    }   

    // send the file
    udf_send_file(fp, argv[1], 42042);
    fclose( fp );

    return 0;
}