
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

int uft_send_file( FILE *fp,  const char* ip, uint16_t port);
int uft_receive_file( FILE *fp,  uint16_t port);
void uft_set_verbosity(int v);
int uft_write_user_register(const char* ip, uint16_t port, uint32_t regadr, uint32_t regval);

#endif
