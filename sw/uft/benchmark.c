/*
* @Author: Noah Huetter
* @Date:   2017-10-27 08:44:26
* @Last Modified by:   Noah Huetter
* @Last Modified time: 2018-03-28 16:14:15
*/


#include "uft.h"
#include <printf.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#define NET_SOFTERROR -1
#define NET_HARDERROR -2

#define TX_BUF_BENCH_N_TESTS 5

static float* txBufBench (const char* ip, uint16_t port);

static void errmemStats(int* errmem, size_t size);
static void waitForSocketWriteReady(int fd);

int main(int argc, char const *argv[])
{
    uint16_t bench;
    const char* ip;
    int port;
    int runs = 20;

    float* stats;
    float cstats[runs][TX_BUF_BENCH_N_TESTS];

    if(argc < 3)
    {
        printf("Usage: ./benchmark IP port [benchnumber]\n");
        exit(1);
    }
    ip = argv[1];
    port = atoi(argv[2]);

    if(argc == 4)
    {
        bench = atoi(argv[3]);

        printf("Running benchmark %d to %s:%d\n", bench, ip, port);
        
        switch(bench)
        {
            case 0:
                for(int i = 0; i < runs; i++)
                {
                    stats = txBufBench(ip, port);
                    memcpy(cstats[i], stats, TX_BUF_BENCH_N_TESTS*sizeof(float));
                }
                printf("----------------------------------------\n");
                printf("To paste in MATLAB\n");
                printf("----------------------------------------\n");
                printf("x = [\n");
                for(int i = 0; i < TX_BUF_BENCH_N_TESTS; i++)
                {
                    for(int j = 0; j < runs; j++)
                        printf("%.3f, ", cstats[j][i]);
                    printf("; \n");
                }
                printf("];\n");
                printf("----------------------------------------\n");
                break;
        }
    }
    else
    {
        printf("Running all benchmarks to %s:%d\n", ip, port);
        (void)txBufBench(ip, port);

    }

    return 0;
}

//////////////////////////////////////////////////////////////////////////////// 
// 
//////////////////////////////////////////////////////////////////////////////// 

/**
 * @brief      Tests what the fastest way to write to the tx buffer is
 *
 * @param[in]  ip    ip address as string
 * @param[in]  port  The port
 *
 * @return     pointer to an array containing the throughputs of each test
 */
static float* txBufBench (const char* ip, uint16_t port)
{
    const int udpPacketSize = 1024;
    const int nPacketsSend = 10000;

    int fd, flags;
    static uint8_t data[1500];
    struct sockaddr_in sa;
    int errmem[nPacketsSend];
    tictoc_t tt;
    float* stats;

    stats = malloc(TX_BUF_BENCH_N_TESTS*sizeof(float));

    printf("-------------------------\n");
    printf("-- TX buffer benchmark --\n");
    printf("-- payload %4d        --\n", udpPacketSize);
    printf("-- cnt %3d           --\n", nPacketsSend);
    printf("-------------------------\n");

    /* Prepare data */
    memset(data, 'x', udpPacketSize); // set data payload to 0
    memset(errmem, 0, nPacketsSend*sizeof(int)); // set error memory to 0
    inet_aton(ip, &(sa.sin_addr));  // convert ip address
    sa.sin_port = htons(port);      // convert port
    sa.sin_family = AF_INET;        // set inet property on socket
    tt.bytes = udpPacketSize*nPacketsSend;
    tt.fp = 0;

    // /* First a normal UDP socket using sendto */
    // printf("-------------------------\n");
    // printf("Using sendto\n");
    // printf("-------------------------\n");
    // // create socket
    // fd = Socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    // // write to socket as fast as possible
    // tic(&tt);
    // for(int i = 0; i < nPacketsSend; i++)
    // {
    //     if(sendto(fd, data, udpPacketSize, 0, (const struct sockaddr*)(&sa), sizeof(sa)) != udpPacketSize)
    //     {
    //         errmem[i] = errno;
    //     }
        
    // }
    // toc(&tt);
    // stats[0] = tt.throughput;
    // // statistics
    // errmemStats(errmem, sizeof(errmem)/sizeof(int));
    // close(fd);

    // /* Connect socket and using send */
    // usleep(500000);
    // printf("-------------------------\n");
    // printf("Using connect and send\n");
    // printf("-------------------------\n");
    // memset(errmem, 0, nPacketsSend*sizeof(int)); // set error memory to 0
    // // create socket
    // fd = Socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    // // conenct socket
    // Connect(fd, (const struct sockaddr*)(&sa), sizeof(sa));
    // // write to socket as fast as possible
    // tic(&tt);
    // for(int i = 0; i < nPacketsSend; i++)
    // {
    //     if(send(fd, data, udpPacketSize, 0) != udpPacketSize)
    //     {
    //         errmem[i] = errno;
    //     }
    // }
    // toc(&tt);
    // stats[1] = tt.throughput;
    // // statistics
    // errmemStats(errmem, sizeof(errmem)/sizeof(int));
    // close(fd);

    // /* Connect socket using send and blocking socket*/
    // usleep(500000);
    // printf("-------------------------\n");
    // printf("Using connect and send nonblocking\n");
    // printf("  This is platform dependant. OSX (BSD) does not support blocking send at all.\n");
    // printf("-------------------------\n");
    // memset(errmem, 0, nPacketsSend*sizeof(int)); // set error memory to 0
    // // create socket
    // fd = Socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    // // set blocking
    // flags = fcntl(fd, F_GETFL, 0);
    // // flags &= ~O_NONBLOCK; // clear the nonblock flag
    // flags |=  O_NONBLOCK; // set the nonblock flag
    // fcntl(fd, F_SETFL, flags);
    // // conenct socket
    // Connect(fd, (const struct sockaddr*)(&sa), sizeof(sa));
    // // write to socket as fast as possible
    // tic(&tt);
    // for(int i = 0; i < nPacketsSend; i++)
    // {
    //     if(send(fd, data, udpPacketSize, 0) != udpPacketSize)
    //     {
    //         errmem[i] = errno;
    //     }
    // }
    // toc(&tt);
    // stats[2] = tt.throughput;
    // // statistics
    // errmemStats(errmem, sizeof(errmem)/sizeof(int));
    // close(fd);

    /* Connect socket using send polling*/
    usleep(500000);
    printf("-------------------------\n");
    printf("Using connect, send and select polling\n");
    printf("-------------------------\n");
    memset(errmem, 0, nPacketsSend*sizeof(int)); // set error memory to 0
    // create socket
    fd = Socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    // set blocking
    flags = fcntl(fd, F_GETFL, 0);
    // flags &= ~O_NONBLOCK; // clear the nonblock flag
    flags |=  O_NONBLOCK; // set the nonblock flag
    fcntl(fd, F_SETFL, flags);
    // conenct socket
    Connect(fd, (const struct sockaddr*)(&sa), sizeof(sa));
    // write to socket as fast as possible
    tic(&tt);
    for(int i = 0; i < nPacketsSend; i++)
    {
        waitForSocketWriteReady(fd);
        if(send(fd, data, udpPacketSize, 0) != udpPacketSize)
        {
            errmem[i] = errno;
        }
    }
    toc(&tt);
    stats[3] = tt.throughput;
    // statistics
    errmemStats(errmem, sizeof(errmem)/sizeof(int));
    close(fd);

    /* Looping if ENOBUFS */
    usleep(500000);
    printf("-------------------------\n");
    printf("Looping if ENOBUFS \n");
    printf("-------------------------\n");
    memset(errmem, 0, nPacketsSend*sizeof(int)); // set error memory to 0
    // create socket
    fd = Socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    // set blocking
    // flags = fcntl(fd, F_GETFL, 0);
    // // flags &= ~O_NONBLOCK; // clear the nonblock flag
    // flags |=  O_NONBLOCK; // set the nonblock flag
    // fcntl(fd, F_SETFL, flags);
    // conenct socket
    Connect(fd, (const struct sockaddr*)(&sa), sizeof(sa));
    // write to socket as fast as possible
    tic(&tt);
    for(int i = 0; i < nPacketsSend; )
    {
        if(send(fd, data, udpPacketSize, 0) != udpPacketSize)
        {
            if (errno == ENOBUFS)
            {
                // dont increment
            }
            else
            {
                errmem[i] = errno;
                i++;
            }
        }
        else
        {
            i++;
        }
    }
    toc(&tt);
    stats[4] = tt.throughput;
    // statistics
    errmemStats(errmem, sizeof(errmem)/sizeof(int));
    close(fd);

    return stats;
}

static void errmemStats(int* errmem, size_t size)
{
    int cntEAGAIN = 0;
    int cntENOBUFS = 0;
    int cntETIMEDOUT = 0;
    int cntOTHER = 0;
    int cntECONNREFUSED = 0;
    int total = 0;
    // count 
    for(size_t i = 0; i < size; i++)
    {
        if(errmem[i] == EAGAIN) cntEAGAIN++;
        else if(errmem[i] == ENOBUFS) cntENOBUFS++;
        else if(errmem[i] == ETIMEDOUT) cntETIMEDOUT++;
        else if(errmem[i] == ECONNREFUSED) cntECONNREFUSED++;
        else if(errmem[i] != 0) { printf("%d ",errmem[i]); cntOTHER++; }
    }

    total = cntEAGAIN + cntENOBUFS + cntETIMEDOUT + cntOTHER + cntECONNREFUSED;

    printf("Erorr statistics:\n");
    printf("  EAGAIN        %d\n",cntEAGAIN);
    printf("  ENOBUFS       %d\n",cntENOBUFS);
    printf("  ETIMEDOUT     %d\n",cntETIMEDOUT);
    printf("  ECONNREFUSED  %d\n",cntECONNREFUSED);
    printf("  other         %d\n",cntOTHER);
    printf("  total         %d\n",total);
    printf("  error percentage: %.3f%%\n",100.0/size*total);
}

static void waitForSocketWriteReady(int fd)
{
   fd_set writeSet;
   FD_ZERO(&writeSet);
   FD_SET(fd, &writeSet);
   if (select(fd+1, NULL, &writeSet, NULL, NULL) < 0) perror("select");
}
