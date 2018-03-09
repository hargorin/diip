/*
* @Author: Noah Huetter
* @Date:   2017-10-27 08:44:26
* @Last Modified by:   Noah Huetter
* @Last Modified time: 2018-03-09 14:02:17
*/


#include "uft.h"
#include <printf.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char const *argv[])
{
    uint16_t port;
    const char *fname;

    if(argc < 2)
    {
        printf("Usage: receiver [port] filename\n");
        return 0;
    }
    if(argc < 3)
    {
        printf("Using default receive port 2222\n");
        port = 2222;
        fname = argv[1];
    }
    else
    {
        port = atoi(argv[1]);
        fname = argv[2];
    }


    printf("UFT Receiver demo\n");
    printf("listening on %d\n", port);

    // open file for sending
    FILE *fp = fopen( fname, "w" );
    if(fp == 0)
    {
        printf("Error: File not found\n");
        return -1;
    }   

    // send the file
    uft_receive_file(fp, port);
    fclose( fp );

    return 0;
}