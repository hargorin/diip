#ifndef _UTIL_H
#define _UTIL_H


#include <stdio.h>
#include <stdint.h>
#include <sys/time.h>


#ifdef __cplusplus
extern "C" {
#endif

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
void hexDump(uint8_t* data, uint32_t size, uint8_t width);

#ifdef __cplusplus
}
#endif

#endif