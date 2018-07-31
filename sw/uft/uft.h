
#ifndef UFT_H
#define UFT_H

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdarg.h>
#include <string.h>

#include <sys/stat.h>

#include <sys/types.h> 
#include <sys/socket.h>
#include <sys/uio.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <poll.h>
#include <fcntl.h>

#include <errno.h>

#include <unistd.h>
#include <netdb.h>

#include "error.h"
#include "wrapper.h"
#include "util.h"

#ifdef __cplusplus
extern "C" {
#endif

enum {
	UFT_CONT_CNONE,
	UFT_CONT_CRESTART,
};

enum {
	UFT_CONT_SINIT,
	UFT_CONT_SWAITFTS,
	UFT_CONT_SRX,
	UFT_CONT_SFTP,
	UFT_CONT_SMEMFULL,
};

int uft_send_file( FILE *fp,  const char* ip, uint16_t port);
int uft_receive_file( FILE *fp,  uint16_t port);
int uft_send_data( uint8_t* data, size_t datasize,  const char* ip, uint16_t port);
int uft_receive_data( uint8_t* data, uint16_t port);

int uft_continuous_receive( uint8_t* data, uint32_t size, uint16_t port, 
    uint32_t control, uint32_t* status);

void uft_set_verbosity(int v);
int uft_write_user_register(const char* ip, uint16_t port, uint32_t regadr, uint32_t regval);

#ifdef __cplusplus
}
#endif

#endif
