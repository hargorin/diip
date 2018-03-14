/*
* @Author: Noah Huetter
* @Date:   2017-10-27 08:44:34
* @Last Modified by:   Noah Huetter
* @Last Modified time: 2018-03-14 14:18:19
*/

#include "uft.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
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

#include <sys/time.h>

// ========================================================
// Data types
// ========================================================
typedef enum uftControll 
{
    FTS,
    FTP,
    ACKFP,
    ACKFT
} tUFTControll;


// Command field values
#define CONTROLL_FTS         0x00
#define CONTROLL_FTP         0x01
#define CONTROLL_ACKFP       0x02
#define CONTROLL_ACKFT       0x03

#define UFT_CONTROLL_SIZE    34 // data plus padding
#define UFT_DATA_PAYLOAD     1464 // remaining data size in data packet
#define UFT_DATA_SIZEW       1472 // data packet size

#define N_PACK_RETRY            10  // how many times to resend a packets

// ========================================================
// Function declarations
// ========================================================

// Socket related
static int create_send_socket(const char* ip, uint16_t port, struct sockaddr_in *sa );
static int create_recv_socket(uint16_t port, struct sockaddr_in *sa );
static int create_reply_socket(uint16_t port, struct sockaddr_in *sa);

static void assemble_uft_controll (uint8_t *buf, uint8_t tcid, uint32_t nseq);
static void assemble_uft_ackfp (uint8_t *buf, uint8_t tcid, uint32_t seqnbr);
static uint32_t assemble_data(uint8_t *buf, FILE *fd, uint32_t fsize, uint8_t tcid, uint32_t seq);

static uint32_t get_filesize_bytes (FILE *fp);

static int is_command_packet(uint8_t *buf);
static int get_command (uint8_t *buf);
static uint8_t get_tcid (uint8_t *buf);
static uint32_t get_nseq (uint8_t *buf);
static uint32_t get_seq (uint8_t *buf);
static uint8_t get_data_tcid (uint8_t *buf);
static uint32_t get_data_seqnbr (uint8_t *buf);
static uint32_t get_command_ackfp_seqnbr (uint8_t *buf);

static uint32_t ack_stats(uint8_t* ack_buf, uint32_t nseq);

int dbgprintf(const char *fmt, ...);

// ========================================================
// Module static data
// ========================================================
static int verbosity = 1;

// ========================================================
// Macros
// ========================================================
// Debug verbosity 1
#define DBG_V1(...) if(verbosity > 0) dbgprintf(__VA_ARGS__)

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
int uft_send_file( FILE *fp,  const char* ip, uint16_t port)
{
    int sockfd, rxsockfd;
    struct sockaddr_in sa, sr;
    int slen = sizeof(sa);
    int srlen = sizeof(sr);

    uint8_t *controll;
    uint8_t *dbuf;
    uint32_t num;

    uint8_t tcid = 12;
    uint32_t nseq, nack_ctr; 
    int count, recv_len;
    uint8_t buf[1500];

    uint8_t *ack_buf;

    // calculate nseq
    int32_t filesize_bytes = get_filesize_bytes(fp);
    nseq = filesize_bytes / UFT_DATA_PAYLOAD;
    if( (filesize_bytes % UFT_DATA_PAYLOAD) != 0)
    {
        nseq++;
    }

    // make room for ack array and set all to 0
    ack_buf = malloc( nseq * sizeof(uint8_t) );
    memset(ack_buf, 0, nseq * sizeof(uint8_t));

    // Create send socket
    sockfd = create_send_socket(ip, port, &sa);
    if (sockfd < 0) return -1;

    // create UDP receive socket
    rxsockfd = create_recv_socket(port+1, &sr);
    if(rxsockfd < 0) return -1;

    // send file start control
    controll = malloc( UFT_CONTROLL_SIZE * sizeof(uint8_t) );
    memset(controll, 0x0, UFT_CONTROLL_SIZE);
    assemble_uft_controll(controll, tcid, nseq);

    //send the message
    if (sendto(sockfd, controll, UFT_CONTROLL_SIZE , 0 , (struct sockaddr *) &sa, slen)==-1)
    {
        printf("Error in: sendto() %s:%d", __FILE__, __LINE__);
        return -1;
    }

    // start data transmission
    dbuf = malloc( UFT_DATA_SIZEW * sizeof(uint8_t) );
    memset(dbuf, 0x0, UFT_DATA_SIZEW);
    for(int i = 0; i < nseq; i++)
    {
        num = assemble_data(dbuf, fp, filesize_bytes, tcid, i);
        //send the message
        if (sendto(sockfd, dbuf, num , 0 , (struct sockaddr *) &sa, slen)==-1)
        {
            printf("Error in: sendto() %s:%d", __FILE__, __LINE__);
            return -1;
        }
        // Check if packet received
        ioctl(rxsockfd, FIONREAD, &count);
        if(count > 0)
        {
            if ((recv_len = recvfrom(rxsockfd, buf, 1500, 0, (struct sockaddr *) &sr, (socklen_t *) &srlen)) == -1)
            {
                printf("\nrcvfrom error: %s %s:%d\n", strerror(errno), __FILE__, __LINE__);
                return -1;
            }
            // Check for ACK package
            if(get_command(buf) == CONTROLL_ACKFP)
            {
                DBG_V1("Command %d: ",get_command(buf));   
                DBG_V1("ack %d\n", get_command_ackfp_seqnbr(buf));
                ack_buf[get_command_ackfp_seqnbr(buf)] = 1;
            }
        }


        // usleep(5); // local: gets some trouble
        usleep(15); // local: no problem at all
    }

    // wait a bit for the last few acks
    struct timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = 100000;
    if (setsockopt(rxsockfd, SOL_SOCKET, SO_RCVTIMEO,&tv,sizeof(tv)) < 0) {
        printf("Error %s %s:%d", strerror(errno), __FILE__, __LINE__);
    }
    int do_it = 1;
    while(do_it)
    {
        if ((recv_len = recvfrom(rxsockfd, buf, 1500, 0, (struct sockaddr *) &sr, (socklen_t *) &srlen)) == -1)
        {
            if(errno == EAGAIN)
            {
                // this means timeout
                do_it = 0;
            }
            else
            {
                printf("\nrcvfrom error: %s %s:%d\n", strerror(errno), __FILE__, __LINE__);
                return -1;
            }
        }
        if(do_it != 0)
        {
            // Check for ACK package
            if(get_command(buf) == CONTROLL_ACKFP)
            {
                DBG_V1("Command %d: ",get_command(buf));   
                DBG_V1("ack %d\n", get_command_ackfp_seqnbr(buf));
                ack_buf[get_command_ackfp_seqnbr(buf)] = 1;
            }
        }
    }
    
    nack_ctr = ack_stats(ack_buf, nseq);

    for (int retrycnt = 0; (retrycnt < N_PACK_RETRY) && nack_ctr; retrycnt++)
    {
        // Resend packages that were not acknowledged
        for(int i = 0; i < nseq; i++)
        {
            // Check if sequence was acknowledged
            if (ack_buf[i])
            {
                continue;
            }
            DBG_V1("Resending seq %d\n",i);
            // else, send packet
            num = assemble_data(dbuf, fp, filesize_bytes, tcid, i);
            //send the message
            if (sendto(sockfd, dbuf, num , 0 , (struct sockaddr *) &sa, slen)==-1)
            {
                printf("Error in: sendto() %s:%d", __FILE__, __LINE__);
                return -1;
            }
            // Check if packet received
            ioctl(rxsockfd, FIONREAD, &count);
            if(count > 0)
            {
                if ((recv_len = recvfrom(rxsockfd, buf, 1500, 0, (struct sockaddr *) &sr, (socklen_t *) &srlen)) == -1)
                {
                    printf("\nrcvfrom error: %s %s:%d\n", strerror(errno), __FILE__, __LINE__);
                    return -1;
                }
                // Check for ACK package
                if(get_command(buf) == CONTROLL_ACKFP)
                {
                    DBG_V1("Command %d: ",get_command(buf));   
                    DBG_V1("ack %d\n", get_command_ackfp_seqnbr(buf));
                    ack_buf[get_command_ackfp_seqnbr(buf)] = 1;
                }
            }
            usleep(20);
        }

        nack_ctr = ack_stats(ack_buf, nseq);
    }

    close(sockfd);
    close(rxsockfd);
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
int uft_receive_file( FILE *fp,  uint16_t port)
{
    int recv_state = 0;

    struct sockaddr_in si_other, st;
     
    int sockfd, txsockfd, slen = sizeof(si_other) , recv_len, stlen = sizeof(si_other);

    uint8_t buf[1500];

    // data output
    uint8_t *outbuf;
    uint32_t nseq, seqctr, data_ctr, payload_size, obuf_ptr;
    uint8_t tcid, do_receive;
     
    double start, end;
    struct timeval tv;

    uint8_t *controll;

    // create UDP receive socket
    sockfd = create_recv_socket(port, &si_other);
    if(sockfd < 0) return -1;
     
    //keep listening for data
    do_receive = 1;
    printf("Waiting for data...\r\n");
    while(do_receive)
    {    
        //try to receive some data, this is a blocking call
        if ((recv_len = recvfrom(sockfd, buf, 1500, 0, (struct sockaddr *) &si_other, (socklen_t *) &slen)) == -1)
        {
            printf("rcvfrom error: %s %s,%d\n", strerror(errno), __FILE__, __LINE__);
            return -1;
        }

        // Create send socket
        txsockfd = create_reply_socket(port+1, &si_other);
        if (txsockfd < 0) return -1;
         
        //print details of the client/peer and the data received
        // printf("Received packet from %s:%d\n", inet_ntoa(si_other.sin_addr), ntohs(si_other.sin_port));
        // printf("Data: %s\n" , buf);
        // printf("Size: %d\n", recv_len);
        // printf("%3.2f %%\r", 100.0/(float)nseq*seqctr);
     
        // first packet
        if(recv_state == 0)
        {
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
                outbuf = malloc( nseq * UFT_DATA_PAYLOAD * sizeof(uint8_t) );
                memset(outbuf, 0x0, nseq * UFT_DATA_PAYLOAD * sizeof(uint8_t));
                // printf("nseq = %d\n", nseq);
            }
        }
        // all subsequent packets
        else
        {
            if( is_command_packet(buf) == 0 )
            {
            // printf("seqctr = %d\n",seqctr);
                if( get_data_tcid(buf) == tcid)
                {
                    // copy valid data to large buffer
                    // this assumes that the payload is constant until the last packet
                    if(payload_size == 0) payload_size = recv_len - 4;
                    memcpy(&outbuf[ get_seq(buf) * payload_size ], &buf[4], recv_len - 4);
                    data_ctr += recv_len - 4;
                    // printf("buf_idx: %d len: %d payload_size: %d\n", (get_seq(buf) * payload_size), (recv_len - 4), payload_size);
                    
                    // send acknowledge
                    controll = malloc( UFT_CONTROLL_SIZE * sizeof(uint8_t) );
                    memset(controll, 0x0, UFT_CONTROLL_SIZE);
                    assemble_uft_ackfp(controll, tcid, get_data_seqnbr(buf));
                    //send the message
                    if (sendto(txsockfd, controll, UFT_CONTROLL_SIZE , 0 , (struct sockaddr *) &si_other, slen)==-1)
                    {
                        printf("Error in: sendto() %s:%d\n", __FILE__, __LINE__);
                        return -1;
                    }

                    if(++seqctr == nseq)
                    {
                        printf("start writing file\n");
                        // transaction is complete, store file
                        if(fwrite(outbuf, 1, data_ctr, fp) != data_ctr)
                        {
                            printf("fwrite error: %s %s:%d\n", strerror(errno), __FILE__, __LINE__);
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
    
    close(sockfd);
    close(txsockfd);

    printf( "\r\n\r\ntime elapsed: %.0fus Speed: %.3f MB/s\n", (end-start),  1.0*get_filesize_bytes(fp) / 1024.0 / 1024.0 / ((end-start) / 1000000.0));
    printf("Filesize: %d\n", get_filesize_bytes(fp));
    return 0;
}



// ========================================================
// Modul private functions
// ========================================================

/**
 * @brief      Debug line to stdout
 *
 * @param[in]  fmt        The format
 * @param[in]  <unnamed>  variable arguments
 *
 * @return     printf ret
 */
int dbgprintf(const char *fmt, ...)
{
    // printf("(%s) ", "UFT");

    va_list ap;
    va_start(ap, fmt);
    int ret = vprintf(fmt, ap);
    va_end(ap);

    return ret;
}

/**
 * @brief      Creates a UDP socket to send data
 *
 * @param[in]  ip    Destination IP address
 * @param[in]  port  Destination port
 * @param      sa    socket address structure pointer
 *
 * @return     socket id if success
 */
static int create_send_socket(const char* ip, uint16_t port, struct sockaddr_in *sa )
{
    int sockfd;

    // convert ip and port
    inet_aton(ip, &(sa->sin_addr));
    sa->sin_port = htons(port);
    sa->sin_family = AF_INET;

    // send control packet
    sockfd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (sockfd < 0) 
    {
        printf("ERROR opening socket %s:%d\n", __FILE__, __LINE__);
        return -1;
    }
    return sockfd;
}

/**
 * @brief      Creates a UDP receive socket to receive data
 *
 * @param[in]  port  listen port
 * @param      sa    socket address structure pointer
 *
 * @return     socket id if success
 */
static int create_recv_socket(uint16_t port, struct sockaddr_in *sa )
{
    int sockfd;

    //create a UDP socket
    if ((sockfd=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1)
    {
        printf("socket error: %s %s:%d\n", strerror(errno), __FILE__, __LINE__);
        return -1;
    }
     
    // zero out the structure
    memset((uint8_t *) sa, 0, sizeof(*sa));
     
    sa->sin_family = AF_INET;
    sa->sin_port = htons(port);
    sa->sin_addr.s_addr = htonl(INADDR_ANY);
     
    //bind socket to port
    if( bind(sockfd , (struct sockaddr*)sa, sizeof(*sa) ) == -1)
    {
        printf("bind error: %s %s:%d\n", strerror(errno), __FILE__, __LINE__);
        return -1;
    }
    return sockfd;
}

/**
 * @brief      Creates a socket to reply to the sender specified in sa
 *
 * @param      sa    sender info
 *
 * @return     socket, -1 if failed
 */
static int create_reply_socket(uint16_t port, struct sockaddr_in *sa)
{
    int sockfd;

    // convert ip and port
    // inet_aton(ip, &(sa->sin_addr));
    sa->sin_port = htons(port);
    sa->sin_family = AF_INET;

    // send control packet
    sockfd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (sockfd < 0) 
    {
        printf("ERROR opening socket %s:%d\n", __FILE__, __LINE__);
        return -1;
    }
    return sockfd;
}

static void assemble_uft_controll (uint8_t *buf, uint8_t tcid, uint32_t nseq)
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
 * @brief      Assembles a packet acknowledgment packet
 *
 * @param      buf     The buffer
 * @param[in]  tcid    transaction ID
 * @param[in]  seqnbr  sequence number to acknowledge
 */
static void assemble_uft_ackfp (uint8_t *buf, uint8_t tcid, uint32_t seqnbr)
{
    buf[0] = CONTROLL_ACKFP;

    buf[1] = 0;
    buf[2] = 0;
    buf[3] = tcid & 0x7f;

    buf[4] = ((seqnbr & 0xff000000) >> 24);
    buf[5] = ((seqnbr & 0x00ff0000) >> 16);
    buf[6] = ((seqnbr & 0x0000ff00) >>  8);
    buf[7] = ((seqnbr & 0x000000ff) >>  0);
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

    fseek(fd, seq * UFT_DATA_PAYLOAD, SEEK_SET);
    long curr = ftell(fd);

    // enough data for a full data packet
    if((fsize - curr) > UFT_DATA_PAYLOAD)
    {
        num = fread(&buf[4], 1, UFT_DATA_PAYLOAD, fd);
        if(num != UFT_DATA_PAYLOAD)
        {
            printf("Error in: assemble_data(): File read num: %d should be %d", (int)num, UFT_DATA_PAYLOAD);
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

/**
 * @brief      Extracts the current sequence number from a received data packet
 *
 * @param      buf   The buffer
 *
 * @return     The data sequqnce number
 */
static uint32_t get_data_seqnbr (uint8_t *buf)
{
    if (is_command_packet(buf) == 0)
    {
        return (buf[1] << 16) | (buf[2] << 8) | (buf[3] << 0);
    }
    return -1;
}

static uint32_t get_command_ackfp_seqnbr (uint8_t *buf)
{
    if (is_command_packet(buf))
    {
        return ( (buf[4] << 24) | (buf[5] << 16) | (buf[6] << 8) | (buf[7] << 0) );
    }
    return -1;
}

/**
 * @brief      Runs packet acknowledgment statistics
 *
 * @param      ack_buf  The acknowledge buffer
 * @param[in]  nseq     number of sequences in ack_buf
 *
 * @return     number of nack
 */
static uint32_t ack_stats(uint8_t* ack_buf, uint32_t nseq)
{
    // ack statistics
    int nack_ctr = 0;
    for(int i = 0; i < nseq; i++)
    {
        if(ack_buf[i] == 0)
        {
            nack_ctr++;
            // printf("NACK for package %d\n", i);
        }
    }
    // statistics
    if(nack_ctr != 0)
    {
        printf("%d of %d (%.1f%%) packets have not been acknowledged\n", 
            nack_ctr, nseq, 100.0 / nseq * nack_ctr);
    }
    else
    {
        printf("HURRAY! All packets have been acknowledged.\n");
    }
    return nack_ctr;
}



