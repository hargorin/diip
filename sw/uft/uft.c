/*
* @Author: Noah Huetter
* @Date:   2017-10-27 08:44:34
* @Last Modified by:   Noah Huetter
* @Last Modified time: 2018-04-05 16:39:16
*/

#include "uft.h"

#include "wrapper.h"

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
#define CONTROLL_USER        0x04

#define UFT_CONTROLL_SIZE    34 // data plus padding
#define UFT_DATA_PAYLOAD     1024 // remaining data size in data packet
#define UFT_DATA_SIZEW       1472 // data packet size

// #define USE_RETRANSMISSION
// #define USE_ACKNOWLEDGE_ON_SEND
// #define USE_ACKNOWLEDGE_ON_RECEIVE
#define N_PACK_RETRY            30  // how many times to resend a packets

// ========================================================
// Function declarations
// ========================================================

// Socket related
static int create_send_socket(const char* ip, uint16_t port, struct sockaddr_in *sa );
static int create_recv_socket(uint16_t port, struct sockaddr_in *sa );

static void assemble_uft_controll (uint8_t *buf, uint8_t tcid, uint32_t nseq);
static void assemble_uft_ackfp (uint8_t *buf, uint8_t tcid, uint32_t seqnbr);
static uint32_t assemble_data(uint8_t *buf, FILE *fd, uint32_t fsize, uint8_t tcid, uint32_t seq);
static uint32_t assemble_data_from_mem(uint8_t *buf, void *data, uint32_t datasize, uint8_t tcid, uint32_t seq);
static void assemble_uft_user_reg (uint8_t *buf, uint8_t reg, uint32_t dat);

static int is_command_packet(uint8_t *buf);
static int get_command (uint8_t *buf);
static uint8_t get_tcid (uint8_t *buf);
static uint32_t get_nseq (uint8_t *buf);
static uint32_t get_seq (uint8_t *buf);
static uint8_t get_data_tcid (uint8_t *buf);
static uint32_t get_data_seqnbr (uint8_t *buf);
static uint32_t get_command_ackfp_seqnbr (uint8_t *buf);

static uint32_t ack_stats(uint8_t* ack_buf, uint32_t nseq);

static int is_all_set (uint8_t* buf, size_t len);

int dbgprintf(const char *fmt, ...);

// ========================================================
// Module static data
// ========================================================
static int verbosity = 0;

// ========================================================
// Macros
// ========================================================
// Debug verbosity 1
#define DBG_V3(...) if(verbosity >= 3) dbgprintf(__VA_ARGS__)
#define DBG_V2(...) if(verbosity >= 2) dbgprintf(__VA_ARGS__)
#define DBG_V1(...) if(verbosity >= 1) dbgprintf(__VA_ARGS__)

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
    int sockfd;
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
 
    tictoc_t tt;
    tt.fp = fp;

    struct pollfd fds; // for send buffer polling

    // calculate nseq
    int32_t filesize_bytes = get_filesize_bytes(fp);
    nseq = filesize_bytes / UFT_DATA_PAYLOAD;
    DBG_V2("nseq=%d\n",nseq);
    if( (filesize_bytes % UFT_DATA_PAYLOAD) != 0)
    {
        nseq++;
    }

    // make room for ack array and set all to 0
    ack_buf = (uint8_t*)malloc( nseq * sizeof(uint8_t) );
    memset(ack_buf, 0, nseq * sizeof(uint8_t));

    // Create send socket
    sockfd = create_send_socket(ip, port, &sa);
    if (sockfd < 0) return -1;

    // send file start control
    controll = (uint8_t*)malloc( UFT_CONTROLL_SIZE * sizeof(uint8_t) );
    assemble_uft_controll(controll, tcid, nseq);

    //send the message
    Send(sockfd, controll, UFT_CONTROLL_SIZE, 0);

    // start data transmission
    dbuf = (uint8_t*)malloc( UFT_DATA_SIZEW * sizeof(uint8_t) );
    memset(dbuf, 0x0, UFT_DATA_SIZEW);
    if(verbosity) tic(&tt);
    int seq_ctr = 0;
    for(; seq_ctr < nseq; )
    {
        DBG_V3("Sending %d of %d\n",seq_ctr,nseq);
        num = assemble_data(dbuf, fp, filesize_bytes, tcid, seq_ctr);
        //send the message
        // Send(sockfd, dbuf, num , 0);
        if (send(sockfd, dbuf, num, 0) != (ssize_t)num)
        {
            if(errno == ENOBUFS || errno == EAGAIN)
            {

            }
            else
            {
                err_sys("send error");
            }
        }
        else
        {
            // packet got sent successfuly , increment counter
            seq_ctr++;
        }
        // Check if packet received
        ioctl(sockfd, FIONREAD, &count);
        if(count > 0)
        {   
            Recv(sockfd, buf, 1500, 0);
            // Check for ACK package
            if(get_command(buf) == CONTROLL_ACKFP)
            {
                DBG_V3("Command %d: ",get_command(buf));   
                DBG_V3("ack %d\n", get_command_ackfp_seqnbr(buf));
                ack_buf[get_command_ackfp_seqnbr(buf)] = 1;
            }
        }
        usleep(100); 
    }
    usleep(100); 
    // wait a bit for the last few acks
    struct timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = 1000;
    Setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO,&tv,sizeof(tv));

    int do_it = 1;
    while(do_it)
    {
        if ((recv_len = recv(sockfd, buf, 1500, 0)) == -1)
        {
            if(errno == EAGAIN)
            {
                // this means timeout
                do_it = 0;
            }
            else
            {
                DBG_V2("%s:%d \nrcvfrom error: %s\n", __FILE__, __LINE__, strerror(errno));
                return -1;
            }
        }
        if(do_it != 0)
        {
            // Check for ACK package
            if(get_command(buf) == CONTROLL_ACKFP)
            {
                DBG_V3("Command %d: ",get_command(buf));   
                DBG_V3("ack %d\n", get_command_ackfp_seqnbr(buf));
                ack_buf[get_command_ackfp_seqnbr(buf)] = 1;
            }
        }
    }
    
    nack_ctr = ack_stats(ack_buf, nseq);

#ifdef USE_RETRANSMISSION
    for (int retrycnt = 0; (retrycnt < N_PACK_RETRY) && nack_ctr; retrycnt++)
    {
        // Resend packages that were not acknowledged
        for(seq_ctr = 0; seq_ctr < nseq; )
        {
            // Check if sequence was acknowledged
            if (ack_buf[seq_ctr])
            {
                seq_ctr++;
                continue;
            }
            DBG_V3("Resending seq %d\n",seq_ctr);
            // else, send packet
            num = assemble_data(dbuf, fp, filesize_bytes, tcid, seq_ctr);
            //send the message
            // Send(sockfd, dbuf, num , 0);
            if (send(sockfd, dbuf, num, 0) != (ssize_t)num)
            {
                if(errno == ENOBUFS || errno == EAGAIN)
                {

                }
                else
                {
                    err_sys("send error");
                }
            }
            else
            {
                // packet got sent successfuly , increment counter
                seq_ctr++;
            }
            // Check if packet received
            ioctl(sockfd, FIONREAD, &count);
            if(count > 0)
            {
                recv_len = Recv(sockfd, buf, 1500, 0);
                // Check for ACK package
                if(get_command(buf) == CONTROLL_ACKFP)
                {
                    DBG_V3("Command %d: ",get_command(buf));   
                    DBG_V3("ack %d\n", get_command_ackfp_seqnbr(buf));
                    ack_buf[get_command_ackfp_seqnbr(buf)] = 1;
                }
            }
            usleep(1);
        }

        nack_ctr = ack_stats(ack_buf, nseq);
    }
#endif

    if(verbosity) toc(&tt);
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
int uft_receive_file( FILE *fp,  uint16_t port)
{
    int recv_state = 0;

    struct sockaddr_in si_other;
     
    int sockfd, slen = sizeof(si_other) , recv_len;

    uint8_t buf[1500];

    // data output
    uint8_t *outbuf;
    uint32_t nseq, seqctr, data_ctr, payload_size, obuf_ptr;
    uint8_t tcid, do_receive;
    
    uint8_t *ack_buf;

    uint8_t *controll;

    tictoc_t tt;
    tt.fp = fp;

    // create UDP receive socket
    sockfd = create_recv_socket(port, &si_other);
    if(sockfd < 0) return -1;
     
    //keep listening for data
    do_receive = 1;
    DBG_V2("Waiting for data...\r\n");
    while(do_receive)
    {    
        //try to receive some data, this is a blocking call
        if(recv_state)
            recv_len = Recv(sockfd, buf, 1500, 0);
        else
            recv_len = Recvfrom(sockfd, buf, 1500, 0, (struct sockaddr *) &si_other, (socklen_t *) &slen);

        // first packet
        if(recv_state == 0)
        {
            if( get_command(buf) == CONTROLL_FTS )
            {
                if(verbosity) tic(&tt);
                // start of data transmission
                recv_state++;
                tcid = get_tcid(buf);
                nseq = get_nseq(buf);
                seqctr = 0;
                data_ctr = 0;
                obuf_ptr = 0;
                payload_size = 0; // will be set on first data packet
                // allocate enough space to hold the data
                outbuf = (uint8_t*)malloc( nseq * UFT_DATA_PAYLOAD * sizeof(uint8_t) );
                memset(outbuf, 0x0, nseq * UFT_DATA_PAYLOAD * sizeof(uint8_t));
                // make room for ack array and set all to 0
                ack_buf = (uint8_t*)malloc( nseq * sizeof(uint8_t) );
                memset(ack_buf, 0, nseq * sizeof(uint8_t));
                // Connect Socket to receive only from this host
                Connect(sockfd, (const struct sockaddr*)&si_other, sizeof(si_other));
                // DBG_V2("nseq = %d\n", nseq);
            }
        }
        // all subsequent packets
        else
        {
            if( is_command_packet(buf) == 0 )
            {
            // DBG_V2("seqctr = %d\n",seqctr);
                if( get_data_tcid(buf) == tcid)
                {
                    // copy valid data to large buffer
                    // this assumes that the payload is constant until the last packet
                    if(payload_size == 0) payload_size = recv_len - 4;
                    memcpy(&outbuf[ get_seq(buf) * payload_size ], &buf[4], recv_len - 4);
                    data_ctr += recv_len - 4;

                    // send acknowledge
                    controll = (uint8_t*)malloc( UFT_CONTROLL_SIZE * sizeof(uint8_t) );
                    memset(controll, 0x0, UFT_CONTROLL_SIZE);
                    assemble_uft_ackfp(controll, tcid, get_data_seqnbr(buf));
                    //send the message
                    Send(sockfd, controll, UFT_CONTROLL_SIZE , 0);
                        
                    // store acknowledged
                    ack_buf[get_seq(buf)] = 1;

                    // if(++seqctr == nseq)
                    if(is_all_set(ack_buf, nseq))
                    {
                        DBG_V2("start writing file\n");
                        // transaction is complete, store file
                        if(fwrite(outbuf, 1, data_ctr, fp) != data_ctr)
                        {
                            DBG_V2("%s:%d fwrite error: %s\n", __FILE__, __LINE__, strerror(errno));
                            return -1;
                        }
                        if(verbosity) toc(&tt);
                        do_receive = 0;
                    }
                }
            }
        }
    }
    
    close(sockfd);
    return 0;
}

/**
 * @brief      Send data via UFT
 *
 * @param      data  data pointer
 * @param[in]  datasize  number of bytes to send
 * @param[in]  ip    destination ip
 * @param[in]  port  destination port
 *
 * @return     status
 */
int uft_send_data( uint8_t* data, size_t datasize,  const char* ip, uint16_t port)
{
    int sockfd;
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


    tictoc_t tt;
    tt.fp = NULL;

    struct pollfd fds; // for send buffer polling

    DBG_V2("ip=%s port=%d\n",ip,port);

    // calculate nseq
    nseq = datasize / UFT_DATA_PAYLOAD;
    DBG_V2("nseq=%d\n",nseq);
    if( (datasize % UFT_DATA_PAYLOAD) != 0)
    {
        nseq++;
    }

    // make room for ack array and set all to 0
    #ifdef USE_ACKNOWLEDGE_ON_SEND
    uint8_t *ack_buf;
    ack_buf = (uint8_t*)malloc( nseq * sizeof(uint8_t) );
    memset(ack_buf, 0, nseq * sizeof(uint8_t));
    #endif

    // Create send socket
    sockfd = create_send_socket(ip, port, &sa);
    if (sockfd < 0) return -1;

    // send file start control
    controll = (uint8_t*)malloc( UFT_CONTROLL_SIZE * sizeof(uint8_t) );
    assemble_uft_controll(controll, tcid, nseq);

    //send the message
    Send(sockfd, controll, UFT_CONTROLL_SIZE, 0);

    // start data transmission
    dbuf = (uint8_t*)malloc( UFT_DATA_SIZEW * sizeof(uint8_t) );
    memset(dbuf, 0x0, UFT_DATA_SIZEW);
    if(verbosity) tic(&tt);
    int seq_ctr = 0;
    for(; seq_ctr < nseq; )
    {
        DBG_V3("Sending %d of %d\n",seq_ctr,nseq);
        num = assemble_data_from_mem(dbuf, data, datasize, tcid, seq_ctr);
        //send the message
        // Send(sockfd, dbuf, num , 0);
        if (send(sockfd, dbuf, num, 0) != (ssize_t)num)
        {
            if(errno == ENOBUFS || errno == EAGAIN)
            {

            }
            else
            {
                err_sys("send error");
            }
        }
        else
        {
            // packet got sent successfuly , increment counter
            seq_ctr++;
        }
        #ifdef USE_ACKNOWLEDGE_ON_SEND
        // Check if packet received
        ioctl(sockfd, FIONREAD, &count);
        if(count > 0)
        {   
            Recv(sockfd, buf, 1500, 0);
            // Check for ACK package
            if(get_command(buf) == CONTROLL_ACKFP)
            {
                DBG_V3("Command %d: ",get_command(buf));   
                DBG_V3("ack %d\n", get_command_ackfp_seqnbr(buf));
                ack_buf[get_command_ackfp_seqnbr(buf)] = 1;
            }
        }
        #endif
        usleep(5); 
    }


    #ifdef USE_ACKNOWLEDGE_ON_SEND
    // wait a bit for the last few acks
    struct timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = 1000;
    Setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO,&tv,sizeof(tv));

    int do_it = 1;
    while(do_it)
    {
        if ((recv_len = recv(sockfd, buf, 1500, 0)) == -1)
        {
            if(errno == EAGAIN)
            {
                // this means timeout
                do_it = 0;
            }
            else
            {
                DBG_V2("%s:%d \nrcvfrom error: %s\n", __FILE__, __LINE__, strerror(errno));
                return -1;
            }
        }
        if(do_it != 0)
        {
            // Check for ACK package
            if(get_command(buf) == CONTROLL_ACKFP)
            {
                DBG_V3("Command %d: ",get_command(buf));   
                DBG_V3("ack %d\n", get_command_ackfp_seqnbr(buf));
                ack_buf[get_command_ackfp_seqnbr(buf)] = 1;
            }
        }
    }
    nack_ctr = ack_stats(ack_buf, nseq);
    #endif

#ifdef USE_RETRANSMISSION
    for (int retrycnt = 0; (retrycnt < N_PACK_RETRY) && nack_ctr; retrycnt++)
    {
        // Resend packages that were not acknowledged
        for(seq_ctr = 0; seq_ctr < nseq; )
        {
            // Check if sequence was acknowledged
            if (ack_buf[seq_ctr])
            {
                seq_ctr++;
                continue;
            }
            DBG_V3("Resending seq %d\n",seq_ctr);
            // else, send packet
            num = assemble_data_from_mem(dbuf, data, datasize, tcid, seq_ctr);
            //send the message
            // Send(sockfd, dbuf, num , 0);
            if (send(sockfd, dbuf, num, 0) != (ssize_t)num)
            {
                if(errno == ENOBUFS || errno == EAGAIN)
                {

                }
                else
                {
                    err_sys("send error");
                }
            }
            else
            {
                // packet got sent successfuly , increment counter
                seq_ctr++;
            }
            // Check if packet received
            ioctl(sockfd, FIONREAD, &count);
            if(count > 0)
            {
                recv_len = Recv(sockfd, buf, 1500, 0);
                // Check for ACK package
                if(get_command(buf) == CONTROLL_ACKFP)
                {
                    DBG_V3("Command %d: ",get_command(buf));   
                    DBG_V3("ack %d\n", get_command_ackfp_seqnbr(buf));
                    ack_buf[get_command_ackfp_seqnbr(buf)] = 1;
                }
            }
            usleep(1);
        }

        nack_ctr = ack_stats(ack_buf, nseq);
    }
#endif

    if(verbosity) toc(&tt);
    close(sockfd);
    return 0;
}



/**
 * @brief      Receive data
 *
 * @param      data  pointer to data buffer to store data
 * @param[in]  port  source port to listen to
 *
 * @return     number of bytes received
 */
int uft_receive_data( uint8_t* data, uint16_t port)
{
    int recv_state = 0;

    struct sockaddr_in si_other;
     
    int sockfd, slen = sizeof(si_other) , recv_len;

    uint8_t buf[1500];

    // data output
    uint8_t *outbuf;
    uint32_t nseq, seqctr, data_ctr, payload_size, obuf_ptr;
    uint8_t tcid, do_receive;
    
    uint8_t *ack_buf;

    uint8_t *controll;

    tictoc_t tt;
    tt.fp = NULL;


    tictoc_t td;
    td.fp = NULL;
    tic(&td);

    // create UDP receive socket
    sockfd = create_recv_socket(port, &si_other);
    if(sockfd < 0) return -1;
     
    //keep listening for data
    do_receive = 1;
    DBG_V2("Waiting for data...\r\n");
    while(do_receive)
    {    
        //try to receive some data, this is a blocking call
        if(recv_state)
            recv_len = Recv(sockfd, buf, 1500, 0);
        else
            recv_len = Recvfrom(sockfd, buf, 1500, 0, (struct sockaddr *) &si_other, (socklen_t *) &slen);

        // first packet
        if(recv_state == 0)
        {
            if( get_command(buf) == CONTROLL_FTS )
            {
                if(verbosity) tic(&tt);
                // start of data transmission
                recv_state++;
                tcid = get_tcid(buf);
                nseq = get_nseq(buf);
                seqctr = 0;
                data_ctr = 0;
                obuf_ptr = 0;
                payload_size = 0; // will be set on first data packet
                // allocate enough space to hold the data
                // outbuf = (uint8_t*)malloc( nseq * UFT_DATA_PAYLOAD * sizeof(uint8_t) );
                outbuf = data;
                // memset(outbuf, 0x0, nseq * UFT_DATA_PAYLOAD * sizeof(uint8_t));
                // make room for ack array and set all to 0
                ack_buf = (uint8_t*)malloc( nseq * sizeof(uint8_t) );
                memset(ack_buf, 0, nseq * sizeof(uint8_t));
                // Connect Socket to receive only from this host
                Connect(sockfd, (const struct sockaddr*)&si_other, sizeof(si_other));
                // DBG_V2("nseq = %d\n", nseq);
            }
        }
        // all subsequent packets
        else
        {
            if( is_command_packet(buf) == 0 )
            {
            // DBG_V2("seqctr = %d\n",seqctr);
                if( get_data_tcid(buf) == tcid)
                {
                    // copy valid data to large buffer
                    // this assumes that the payload is constant until the last packet
                    if(payload_size == 0) payload_size = recv_len - 4;
                    // printf("seq=%d payload_size=%d recv_len=%d\n",get_seq(buf),payload_size,recv_len);
                    memcpy(&outbuf[ get_seq(buf) * payload_size ], &buf[4], recv_len - 4);
                    data_ctr += recv_len - 4;

                    #ifdef USE_ACKNOWLEDGE_ON_RECEIVE
                    // send acknowledge
                    controll = (uint8_t*)malloc( UFT_CONTROLL_SIZE * sizeof(uint8_t) );
                    memset(controll, 0x0, UFT_CONTROLL_SIZE);
                    assemble_uft_ackfp(controll, tcid, get_data_seqnbr(buf));
                    //send the message
                    Send(sockfd, controll, UFT_CONTROLL_SIZE , 0);
                    #endif 

                    // store acknowledged
                    ack_buf[get_seq(buf)] = 1;

                    // if(++seqctr == nseq)
                    if(is_all_set(ack_buf, nseq))
                    {
                        DBG_V2("Done receiving. Copy to %08x\n", data);
                        // memcpy(data, outbuf, nseq * UFT_DATA_PAYLOAD * sizeof(uint8_t) );
                        if(verbosity) toc(&tt);
                        do_receive = 0;
                    }
                }
            }
        }
    }
    
    close(sockfd);
    return data_ctr;
}

/**
 * @brief      Runs a continuous receive operation. Call periodically and
 * control using control bits
 *
 * @param      data  The data
 * @param      size  Maximum number of bytes to receive
 * @param[in]  port  The port
 * @param[in]  control  Control bits
 *
 * @return     status
 */


/**
 * @brief      Runs a continuous receive operation. Call periodically and
 * control using control bits
 *
 * @param      data     The data
 * @param[in]  size     The maximum size in data
 * @param[in]  port     The port
 * @param[in]  control  The control
 * @param      status   The status
 *
 * @return     bytes received or negative if error
 */
int uft_continuous_receive( uint8_t* data, uint32_t size, uint16_t port, 
    uint32_t control, uint32_t* status)
{
    // All data must be static
    static struct sockaddr_in si_other;
    static int sockfd, dataoff = 0;
    static int ctr = 0;
    static int eintrCtr = 0;

    // state: 
    // 0: init
    // 1: wait for FTS
    // 2: receiving -> wait for FTP
    // 3: FTP received
    // 4: Mem full
    static int state = UFT_CONT_SINIT;

    // some non statics
    int slen = sizeof(si_other), recv_len;
    struct timeval rd_timeout;
    uint8_t buf[1500];

    // Check for a control signal
    if(control == UFT_CONT_CRESTART)
    {
        if(sockfd > 0)
        {
            close(sockfd);
        }
        state = UFT_CONT_SINIT;
        ctr = 0;
        eintrCtr = 0;
        return dataoff;
    }

    // if first call, create and bind socket
    if (state == UFT_CONT_SINIT)
    {
        // create UDP receive socket
        sockfd = create_recv_socket(port, &si_other);
        if(sockfd < 0) 
        {
            *status = state;
            return -1;
        }
        // set socket options to 10us receive timeout
        rd_timeout.tv_sec = 0;
        rd_timeout.tv_usec = 10;
        Setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, &rd_timeout, sizeof(rd_timeout));
        // state change
        state = UFT_CONT_SWAITFTS;
        // reset statics
        dataoff = 0;
    }

    // if file transfer is complete, get ready for next
    if (state == UFT_CONT_SFTP)
    {
        state = UFT_CONT_SWAITFTS;
    }

    // try to receive data
    recv_len = recvfrom(sockfd, buf, 1500, 0, (struct sockaddr *) &si_other, (socklen_t *) &slen);
    if(recv_len == -1)
    {
        if(errno == EAGAIN)
        {
            // this means timeout
            // exit if no receive
            {
                *status = state;
                return dataoff;
            }
        }
        // interupted sys call -> try again
        else if (errno == EINTR)
        {
            if(++eintrCtr == 10)
            {
                printf("%s:%d \nrcvfrom error: %s\n", __FILE__, __LINE__, strerror(errno));
                *status = state;
                return -1;
            }
            else
            {
                // ignore and continue
                *status = state;
                return dataoff;
            }
        }
        else
        {
            printf("%s:%d \nrcvfrom error: %s\n", __FILE__, __LINE__, strerror(errno));
            *status = state;
            return -1;
        }
    }

    // check for command
    if( is_command_packet(buf) )
    {
        if( get_command(buf) == CONTROLL_FTS )
        {
            state = UFT_CONT_SRX;
        }
        if( get_command(buf) == CONTROLL_FTP )
        {
            state = UFT_CONT_SFTP;
        }
    }
    // check for data
    else
    {
        // store data if space
        if (dataoff <= size - (recv_len - 4))
        {
            // printf("Offset = %d\n", dataoff);
            // printf("buf: \n");
            // hexDump(buf, recv_len, 8);
            // printf("rx %d\n",++ctr);
            memcpy(&data[dataoff], &buf[4], recv_len - 4);
            dataoff += recv_len - 4;
        }
        else
        {
            state = UFT_CONT_SMEMFULL;
        }
    }

    // return current state and bytes written
    *status = state;
    return dataoff;
}

/**
 * @brief      Set verbosity level, default 0
 *
 * @param[in]  v     verbosity level
 */
void uft_set_verbosity(int v)
{
    verbosity = v;
}

/**
 * @brief      Set a user register in the receiving host
 *
 * @param[in]  ip      destination ip address
 * @param[in]  port    destination port
 * @param[in]  regadr  user register address 0..7
 * @param[in]  regval  user register data to be written
 *
 * @return     status
 */
int uft_write_user_register(const char* ip, uint16_t port, uint32_t regadr, uint32_t regval)
{
    int sockfd;
    struct sockaddr_in sa;
    uint8_t *controll;

    // Create send socket
    sockfd = create_send_socket(ip, port, &sa);
    if (sockfd < 0) return -1;

    // send file start control
    controll = (uint8_t*)malloc( UFT_CONTROLL_SIZE * sizeof(uint8_t) );
    assemble_uft_user_reg(controll, regadr, regval);

    //send the message
    Send(sockfd, controll, UFT_CONTROLL_SIZE, 0);

    // TODO: read acknowledge
    close(sockfd);
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
    int sockfd, flags;

    // convert ip and port
    inet_aton(ip, &(sa->sin_addr));
    sa->sin_port = htons(port);
    sa->sin_family = AF_INET;

    // send control packet
    sockfd = Socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    // if (sockfd < 0) 
    // {
    //     printf("%s:%d ERROR opening socket: %s\n", __FILE__, __LINE__, strerror(errno));
    //     return -1;
    // }

    // Set flags
    flags = fcntl(sockfd, F_GETFL, 0);
    // set blocking
    // flags &= ~O_NONBLOCK;
    // set nonblocking
    flags |= O_NONBLOCK;
    fcntl(sockfd, F_SETFL, flags);

    // connect socket: Limits UDP connection to single peer
    Connect(sockfd, (const struct sockaddr*)sa, sizeof(*sa));

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
    sockfd = Socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    // if ((sockfd=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1)
    // {
    //     printf("%s:%d socket error: %s\n", __FILE__, __LINE__, strerror(errno));
    //     return -1;
    // }
     
    // zero out the structure
    memset((uint8_t *) sa, 0, sizeof(*sa));
     
    sa->sin_family = AF_INET;
    sa->sin_port = htons(port);
    sa->sin_addr.s_addr = htonl(INADDR_ANY);
     
    //bind socket to port
    Bind(sockfd , (struct sockaddr*)sa, sizeof(*sa) );
    // if( bind(sockfd , (struct sockaddr*)sa, sizeof(*sa) ) == -1)
    // {
    //     printf("%s:%d bind error: %s\n", __FILE__, __LINE__, strerror(errno));
    //     return -1;
    // }
    return sockfd;
}


static void assemble_uft_controll (uint8_t *buf, uint8_t tcid, uint32_t nseq)
{
    memset(buf, 0x0, UFT_CONTROLL_SIZE);

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

    // Method using a local buffer of the file. Turns out to be slower
    // static uint8_t *fbuf = 0;
    // size_t num;

    // // check if file is in buffer
    // if(fbuf == 0)
    // {
    //     // allocate memory
    //     fbuf = malloc( fsize );
    //     if(!fbuf) err_sys ("memory allocation for input file failed");
    //     // copy file to buffer
    //     // num = read(fd, fbuf, fsize);
    //     num = fread(fbuf, 1, fsize, fd);
    //     if (num != fsize)
    //     {
    //         err_quit("Read only %d of %d bytes into buffer", num, fsize);
    //     }
    // }

    // buf[0] = (tcid & 0x7f) | 0x80;

    // buf[1] = ((seq & 0x00ff0000) >> 16);
    // buf[2] = ((seq & 0x0000ff00) >>  8);
    // buf[3] = ((seq & 0x000000ff) >>  0);

    // long curr = seq * UFT_DATA_PAYLOAD;

    // // enough data for a full data packet
    // if((fsize - curr) > UFT_DATA_PAYLOAD)
    // {
    //     num = UFT_DATA_PAYLOAD;
    //     memcpy(&buf[4], &fbuf[seq * UFT_DATA_PAYLOAD], num);
    // }
    // else
    // {
    //     num = fsize - curr;
    //     memcpy(&buf[4], &fbuf[seq * UFT_DATA_PAYLOAD], num);
    // }
    // return  num+4;  
}
/**
 * @brief      Assembles a data packet with data from memory the i-th sequence
 *
 * @param      dbuf  output buffer
 * @param      data  input data
 * param[in] datasize data size in bytes
 * @param[in]  tcid  transaction id
 * @param[in]  seq     sequence number
 * 
 * @return     Returns the data packet size
 */
static uint32_t assemble_data_from_mem(uint8_t *buf, void *data, uint32_t datasize, uint8_t tcid, uint32_t seq)
{
    size_t num;

    buf[0] = (tcid & 0x7f) | 0x80;

    buf[1] = ((seq & 0x00ff0000) >> 16);
    buf[2] = ((seq & 0x0000ff00) >>  8);
    buf[3] = ((seq & 0x000000ff) >>  0);

    long curr = seq * UFT_DATA_PAYLOAD;

    // enough data for a full data packet
    if((datasize - curr) > UFT_DATA_PAYLOAD)
    {
        memcpy(&buf[4], &((uint8_t*)data)[curr], UFT_DATA_PAYLOAD);
        num = UFT_DATA_PAYLOAD;
    }
    else
    {
        memcpy(&buf[4], &((uint8_t*)data)[curr], (datasize - curr));
        num = (datasize - curr);
    }
    return  num+4;  
}

/**
 * @brief      Assemble a set user register packet
 *
 * @param      buf   destination buffer already allocated
 * @param[in]  reg   user target register
 * @param[in]  dat   user target data
 */
static void assemble_uft_user_reg (uint8_t *buf, uint8_t reg, uint32_t dat)
{
    memset(buf, 0x0, UFT_CONTROLL_SIZE);

    buf[0] = CONTROLL_USER;

    buf[1] = 0;
    buf[2] = 0;
    buf[3] = reg & 0x07;

    buf[4] = ((dat & 0xff000000) >> 24);
    buf[5] = ((dat & 0x00ff0000) >> 16);
    buf[6] = ((dat & 0x0000ff00) >>  8);
    buf[7] = ((dat & 0x000000ff) >>  0);
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
    return buf[0] & 0x7f;
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
        DBG_V2("%d of %d (%.1f%%) packets have not been acknowledged\n", 
            nack_ctr, nseq, 100.0 / nseq * nack_ctr);
    }
    else
    {
        DBG_V2("HURRAY! All %d packets have been acknowledged.\n", nseq);
    }
    return nack_ctr;
}


/**
 * @brief      Tests an array for all elements not zero
 *
 * @param      buf   The buffer
 * @param[in]  len   The length
 *
 * @return     True if all set, False otherwise.
 */
static int is_all_set (uint8_t* buf, size_t len)
{
    for (int i = 0; i < len; i++)
    {
        if(buf[i] == 0)
            return 0;
    }
    return 1;
}
