/*
* @Author: Noah Huetter
* @Date:   2017-10-27 08:44:26
* @Last Modified by:   Noah Huetter
* @Last Modified time: 2018-03-09 14:01:37
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
    const char *ip;

    if(argc < 3)
    {
        printf("Usage: ./sender IP [port] filename\n");
        return 0;
    }
    if(argc < 4)
    {
        printf("Using default destination port 42042\n");
        port = 42042;
        fname = argv[2];
        ip = argv[1];
    }
    else
    {
        port = atoi(argv[2]);
        fname = argv[3];
        ip = argv[1];
    }

    printf("UFT Sender demo\n");
    printf("destination %s:%d\n", ip, port);

    // open file for sending
    FILE *fp = fopen( fname, "rb" );
    if(fp == 0)
    {
        printf("Error: File not found\n");
        return -1;
    }   

    // send the file
    uft_send_file(fp, ip, port);
    fclose( fp );

    return 0;
}