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
    gettimeofday(&tt->tv,NULL);
    tt->end = 1000000 * tt->tv.tv_sec + tt->tv.tv_usec;
    if(tt->fp)
    {
        tt->bytes = get_filesize_bytes(tt->fp);
    }
    tt->throughput = 1.0*(tt->bytes) / ((tt->end-tt->start) / 1000000.0);
    printf( "time elapsed: %.0fus Speed: %.3f MB/s Size: %.3f MB\n", 
        (tt->end-tt->start),  
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