/**
 * Source: http://unpbook.com/src.html
 */
/* include checkopts1 */
/* *INDENT-OFF* */

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

int
Socket(int family, int type, int protocol)
{
    int     n;

    if ( (n = socket(family, type, protocol)) < 0)
        printf("socket error");
    return(n);
}

/* *INDENT-ON* */
/* end checkopts1 */

/* include checkopts2 */
int
main(int argc, char **argv)
{
    int                 fd;
    socklen_t           len;
    int do_it = 1;

    int value, defaultval;

    // open socket
    fd = Socket(AF_INET, SOCK_DGRAM, 0);

    printf("Checking SO_RCVBUF\n");
    
    // get value
    len = sizeof(value);
    if (getsockopt(fd, SOL_SOCKET, SO_RCVBUF, &value, &len) == -1) {
        printf("getsockopt error");
    } else {
        printf("default = %d\n", value);
        defaultval = value;
    }

    // increase
    while(do_it)
    {
        value = value + 4;
        if (setsockopt(fd, SOL_SOCKET, SO_RCVBUF, &value, len) == -1) {
            printf("\nsetsockopt error");
            value = value - 4;
            printf("\n\nMax SO_RCVBUF value is %d\n", value);
            printf("%.1f times improvement\n", (float)value/defaultval);
            do_it = 0;
        } else {
            printf("\rnew value = %d", value);
        }
    }

    printf("Checking SO_SNDBUF\n");
    
    // get value
    len = sizeof(value);
    if (getsockopt(fd, SOL_SOCKET, SO_SNDBUF, &value, &len) == -1) {
        printf("getsockopt error");
    } else {
        printf("default = %d\n", value);
        defaultval = value;
    }

    // increase
    do_it = 1;
    while(do_it)
    {
        value = value + 4;
        if (setsockopt(fd, SOL_SOCKET, SO_SNDBUF, &value, len) == -1) {
            printf("\nsetsockopt error");
            value = value - 4;
            printf("\n\nMax SO_SNDBUF value is %d\n", value);
            printf("%.1f times improvement\n", (float)value/defaultval);
            do_it = 0;
        } else {
            printf("\rnew value = %d", value);
        }
    }

    exit(0);
}
/* end checkopts2 */
