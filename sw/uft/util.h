#ifndef _UTIL_H
#define _UTIL_H


#include <stdio.h>
#include <stdint.h>
#include <sys/time.h>


typedef struct tictocstruct
{
    struct timeval tv;
    double start;
    double end;
    FILE* fp;
    size_t bytes;
    float throughput;
} tictoc_t;


void tic(tictoc_t *tt);
void toc(tictoc_t *tt);
uint32_t get_filesize_bytes (FILE *fp);

#endif