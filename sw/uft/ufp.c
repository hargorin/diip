/*
* @Author: Noah Huetter
* @Date:   2017-10-27 08:44:34
* @Last Modified by:   Noah Huetter
* @Last Modified time: 2017-12-02 13:35:44
*/

#include "ufp.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <sys/stat.h>

#include <unistd.h>
#include <sys/types.h> 
#include <sys/socket.h>
#include <sys/uio.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include <errno.h>

#include <unistd.h>
#include <netdb.h>

#include <time.h>

// ========================================================
// Data types
// ========================================================
typedef enum udfControll 
{
    FTS,
    FTP,
    ACKFP,
    ACKFT
} tUDFControll;


// Command field values
#define CONTROLL_FTS         0x00
#define CONTROLL_FTP         0x01
#define CONTROLL_ACKFP       0x02
#define CONTROLL_ACKFT       0x03

#define UDF_CONTROLL_SIZE    34 // data plus padding
#define UDF_DATA_PAYLOAD     1464 // remaining data size in data packet
#define UDF_DATA_SIZEW       1472 // data packet size


// ========================================================
// Function declarations
// ========================================================
static void assemble_fts_controll (uint8_t *buf, uint8_t tcid, uint32_t nseq);
static uint32_t assemble_data(uint8_t *buf, FILE *fd, uint32_t fsize, uint8_t tcid, uint32_t seq);
static uint32_t get_filesize_bytes (FILE *fp);
static int is_command_packet(uint8_t *buf);
static int get_command (uint8_t *buf);
static uint8_t get_tcid (uint8_t *buf);
static uint32_t get_nseq (uint8_t *buf);
static uint32_t get_seq (uint8_t *buf);
static uint8_t get_data_tcid (uint8_t *buf);


// ========================================================
// Modul public functions
// ========================================================

/**
 * @brief      Send a file to a destination ip and port
 *
 * @param      fp    file descriptor
 * @param[in]  ip    destination ip adress
 * @param[in]  port  destination port
 *
 * @return     status
 */
int udf_send_file( FILE *fp,  const char* ip, uint16_t port)
{
    int sockfd;
    uint8_t *controll;
    uint8_t *dbuf;
    struct sockaddr_in sa;
    int slen = sizeof(sa);
    uint32_t num;

    uint8_t tcid = 12;
    uint32_t nseq; 

    // calculate nseq
    int32_t filesize_bytes = get_filesize_bytes(fp);
    nseq = filesize_bytes / UDF_DATA_PAYLOAD;
    if( (filesize_bytes % UDF_DATA_PAYLOAD) != 0)
    {
        nseq++;
    }

    // convert ip and port
    inet_aton(ip, &(sa.sin_addr));
    sa.sin_port = htons(port);
    sa.sin_family = AF_INET;

    // send file start control
    controll = malloc( UDF_CONTROLL_SIZE * sizeof(uint8_t) );
    memset(controll, 0x0, UDF_CONTROLL_SIZE);
    assemble_fts_controll(controll, tcid, nseq);
    
    // send control packet
    sockfd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (sockfd < 0) 
    {
        printf("ERROR opening socket\n");
        return -1;
    }

    //send the message
    if (sendto(sockfd, controll, UDF_CONTROLL_SIZE , 0 , (struct sockaddr *) &sa, slen)==-1)
    {
        printf("Error in: sendto()");
        return -1;
    }

    // start data transmission
    dbuf = malloc( UDF_DATA_SIZEW * sizeof(uint8_t) );
    memset(dbuf, 0x0, UDF_DATA_SIZEW);
    for(int i = 0; i < nseq; i++)
    {
        num = assemble_data(dbuf, fp, filesize_bytes, tcid, i);
        //send the message
        if (sendto(sockfd, dbuf, num , 0 , (struct sockaddr *) &sa, slen)==-1)
        {
            printf("Error in: sendto()");
            return -1;
        }

        usleep(50);
    }

    close(sockfd);
    return 0;
}

/**
 * @brief      Receive a file
 *
 * @param      fp    file descriptor
 * @param[in]  port  source port to listen to
 *
 * @return     status
 */
int udf_receive_file( FILE *fp,  uint16_t port)
{
    int recv_state = 0;

    struct sockaddr_in si_me, si_other;
     
    int s, slen = sizeof(si_other) , recv_len;
    uint8_t buf[1500];

    // data output
    uint8_t *outbuf;
    uint32_t nseq, seqctr, data_ctr, payload_size, obuf_ptr;
    uint8_t tcid, do_receive;
     
    double start, end;
    struct timeval tv;

    //create a UDP socket
    if ((s=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1)
    {
        printf("socket error: %s\n", strerror(errno));
        return -1;
    }
     
    // zero out the structure
    memset((uint8_t *) &si_me, 0, sizeof(si_me));
     
    si_me.sin_family = AF_INET;
    si_me.sin_port = htons(port);
    si_me.sin_addr.s_addr = htonl(INADDR_ANY);
     
    //bind socket to port
    if( bind(s , (struct sockaddr*)&si_me, sizeof(si_me) ) == -1)
    {
        printf("bind error: %s\n", strerror(errno));
        return -1;
    }
     
    //keep listening for data
    do_receive = 1;
    printf("Waiting for data...\r\n");
    while(do_receive)
    {    
        //try to receive some data, this is a blocking call
        if ((recv_len = recvfrom(s, buf, 1500, 0, (struct sockaddr *) &si_other, (socklen_t *) &slen)) == -1)
        {
            printf("rcvfrom error: %s\n", strerror(errno));
            return -1;
        }
         
        //print details of the client/peer and the data received
        // printf("Received packet from %s:%d\n", inet_ntoa(si_other.sin_addr), ntohs(si_other.sin_port));
        // printf("Data: %s\n" , buf);
        // printf("Size: %d\n", recv_len);
        // printf("%3.2f %%\r", 100.0/(float)nseq*seqctr);
         
        switch(recv_state)
        {
            case 0:
                if( get_command(buf) == CONTROLL_FTS )
                {
                    gettimeofday(&tv,NULL);
                    start = 1000000 * tv.tv_sec + tv.tv_usec;
                    // start of data transmission
                    recv_state++;
                    tcid = get_tcid(buf);
                    nseq = get_nseq(buf);
                    seqctr = 0;
                    data_ctr = 0;
                    obuf_ptr = 0;
                    payload_size = 0; // will be set on first data packet
                    // allocate enough space to hold the data
                    outbuf = malloc( nseq * UDF_DATA_PAYLOAD * sizeof(uint8_t) );
                    memset(outbuf, 0x0, nseq * UDF_DATA_PAYLOAD * sizeof(uint8_t));
                    printf("nseq = %d\n", nseq);
                }
                break;
            case 1:
                if( is_command_packet(buf) == 0 )
                {
                printf("seqctr = %d\n",seqctr);
                    if( get_data_tcid(buf) == tcid)
                    {
                        printf("get_data_tcid(buf) == tcid\n");
                        // copy valid data to large buffer
                        // this assumes that the payload is constant until the last packet
                        if(payload_size == 0) payload_size = recv_len - 4;
                        memcpy(&outbuf[ get_seq(buf) * payload_size ], &buf[4], recv_len - 4);
                        data_ctr += recv_len - 4;
                        printf("buf_idx: %d len: %d payload_size: %d\n", (get_seq(buf) * payload_size), (recv_len - 4), payload_size);
                        if(++seqctr == nseq)
                        {
                            printf("start writing file\n");
                            // transaction is complete, store file
                            if(fwrite(outbuf, 1, data_ctr, fp) != data_ctr)
                            {
                                printf("fwrite error: %s\n", strerror(errno));
                                return -1;
                            }
                            gettimeofday(&tv,NULL);
                            end = 1000000 * tv.tv_sec + tv.tv_usec;
                            do_receive = 0;
                        }
                    }
                }
        }
    }
    
    close(s);

    printf( "\r\n\r\ntime elapsed: %.0fus Speed: %.3f MB/s\n", (end-start),  get_filesize_bytes(fp) / 1024 / 1024 / ((end-start) / 1000000));
    return 0;
}



// ========================================================
// Modul private functions
// ========================================================
static void assemble_fts_controll (uint8_t *buf, uint8_t tcid, uint32_t nseq)
{
    buf[0] = CONTROLL_FTS;

    buf[1] = 0;
    buf[2] = 0;
    buf[3] = tcid & 0x7f;

    buf[4] = ((nseq & 0xff000000) >> 24);
    buf[5] = ((nseq & 0x00ff0000) >> 16);
    buf[6] = ((nseq & 0x0000ff00) >>  8);
    buf[7] = ((nseq & 0x000000ff) >>  0);
}

/**
 * @brief      Assembles a data packet with data from the file fd the i-th sequence
 *
 * @param      dbuf  output buffer
 * @param      fd    input data file
 * param[in] fsize file size in bytes
 * @param[in]  tcid  transaction id
 * @param[in]  i     sequence number
 * 
 * @return     Returns the data packet size
 */
static uint32_t assemble_data(uint8_t *buf, FILE *fd, uint32_t fsize, uint8_t tcid, uint32_t seq)
{
    size_t num;

    buf[0] = (tcid & 0x7f) | 0x80;

    buf[1] = ((seq & 0x00ff0000) >> 16);
    buf[2] = ((seq & 0x0000ff00) >>  8);
    buf[3] = ((seq & 0x000000ff) >>  0);

    fseek(fd, seq * UDF_DATA_PAYLOAD, SEEK_SET);
    long curr = ftell(fd);

    // enough data for a full data packet
    if((fsize - curr) > UDF_DATA_PAYLOAD)
    {
        num = fread(&buf[4], 1, UDF_DATA_PAYLOAD, fd);
        if(num != UDF_DATA_PAYLOAD)
        {
            printf("Error in: assemble_data(): File read num: %d should be %d", (int)num, UDF_DATA_PAYLOAD);
        }
    }
    else
    {
        num = fread(&buf[4], 1, (fsize - curr), fd);  
        if(num != (fsize - curr))
        {
            printf("Error in: assemble_data(): File read num: %d should be %d", (int)num, (int)(fsize - curr));
        }
    }
    return  num+4;  
}

/**
 * @brief      Returns the file size in bytes
 *
 * @param      fp    pointer to an open file descriptor
 *
 * @return     The filesize bytes.
 */
static uint32_t get_filesize_bytes (FILE *fp)
{
    struct stat stat_buf;
    int rc = fstat(fileno(fp), &stat_buf);
    return rc == 0 ? stat_buf.st_size : -1;
}

/**
 * @brief      Returns 1 if the received packet is a command, 0 if data
 *
 * @param      buf   received packet
 *
 * @return     True if command packet, False otherwise.
 */
static int is_command_packet (uint8_t *buf)
{
    if( buf[0] & 0x80 ) return 0;
    return 1;
}

/**
 * @brief      extracts the command from a packet
 *
 * @param      buf   The buffer
 *
 * @return     The command.
 */
static int get_command (uint8_t *buf)
{
    if (is_command_packet(buf))
    {
        switch( buf[0] & 0x7f )
        {
            case CONTROLL_FTS: return CONTROLL_FTS;
            case CONTROLL_FTP: return CONTROLL_FTP;
            case CONTROLL_ACKFP: return CONTROLL_ACKFP;
            case CONTROLL_ACKFT: return CONTROLL_ACKFT;
            default: return -1;
        }
    }
    return -1;
}

/**
 * @brief      extracts the transaction id from the command packet
 *
 * @param      buf   The buffer
 *
 * @return     transaction id
 */
static uint8_t get_tcid (uint8_t *buf)
{
    if (is_command_packet(buf))
    {
        return buf[3];
    }
    return -1;
}

/**
 * @brief      Extracts the number of sequences of a command packet
 *
 * @param      buf   The buffer
 *
 * @return     number of sequences to be transmitted
 */
static uint32_t get_nseq (uint8_t *buf)
{
    if (is_command_packet(buf))
    {
        return ( (buf[4] << 24) | (buf[5] << 16) | (buf[6] << 8) | (buf[7] << 0) );
    }
    return -1;
}

/**
 * @brief      returns the sequence number of a data packet
 *
 * @param      buf   The buffer
 *
 * @return     sequence number of the data packet
 */
static uint32_t get_seq (uint8_t *buf)
{
    if (is_command_packet(buf) == 0)
    {
        return (buf[1] << 16) | (buf[2] << 8) | (buf[3] << 0);
    }
    return -1;
}

/**
 * @brief      extracts the transaction id from the data packet
 *
 * @param      buf   The buffer
 *
 * @return     transaction id
 */
static uint8_t get_data_tcid (uint8_t *buf)
{
    if (is_command_packet(buf) == 0)
    {
        return buf[0] & 0x7f;
    }
    return -1;
}






