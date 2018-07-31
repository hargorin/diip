/*
* @Author: Noah Huetter
* @Date:   2018-03-28 11:34:54
* @Last Modified by:   Noah Huetter
* @Last Modified time: 2018-03-28 15:34:21
*/
#include "util.h"

#include <stdlib.h>
#include <sys/stat.h>

/**
 * @brief      Start time measurement
 *
 * @param      tt    tictoc_t structure
 */
void tic(tictoc_t *tt)
{
    gettimeofday(&tt->tv,NULL);
    tt->start = 1000000 * tt->tv.tv_sec + tt->tv.tv_usec;
}

/**
 * @brief      Stop time measurement and report elapsed, speed and filesize
 *
 * @param      tt    tictoc_t structure
 */
void toc(tictoc_t *tt)
{
    char timestring[20];
    gettimeofday(&tt->tv,NULL);
    tt->end = 1000000 * tt->tv.tv_sec + tt->tv.tv_usec;
    if(tt->fp)
    {
        tt->bytes = get_filesize_bytes(tt->fp);
    }
    tt->throughput = 1.0*(tt->bytes) / ((tt->end-tt->start) / 1000000.0);
    // time calc
    int dt = tt->end-tt->start;
    if (dt > 1e6) {
        snprintf(timestring, 20, "%.2fs", (float)dt/1.0e6);
    } else if (dt > 1e3) {
        snprintf(timestring, 20, "%.2fms", (float)dt/1.0e3);
    }
    else {
        snprintf(timestring, 20, "%.2fus", (float)dt/1.0);
    }


    printf( "time elapsed: %s Speed: %.3f MB/s Size: %.3f MB\n", 
        (timestring),  
        tt->throughput / 1024.0 / 1024.0,
        tt->bytes/1024.0/1024.0);
}
/**
 * @brief      Returns the file size in bytes
 *
 * @param      fp    pointer to an open file descriptor
 *
 * @return     The filesize bytes.
 */
uint32_t get_filesize_bytes (FILE *fp)
{
    struct stat stat_buf;
    int rc = fstat(fileno(fp), &stat_buf);
    return rc == 0 ? stat_buf.st_size : -1;
}

/**
 * @brief      Dumps the memory as hez
 *
 * @param      data   The data
 * @param[in]  size   The size
 * @param[in]  width  The width of the dump in two byes
 */
void hexDump(uint8_t* data, uint32_t size, uint8_t width)
{
    int byteCnt = 0;
    int byteCnt2 = 0;
    printf("%08x: ", 0);  
    for (int i = 0; i < size; i++)
    {
        printf("%02x", data[i]);
        if(++byteCnt2 == 2) {
            byteCnt2 = 0;
            printf(" ");  
        } 
        if(++byteCnt == 32) {
            byteCnt = 0;
            printf("\n");  
            printf("%08x: ", i+1);  
        } 
    }
}