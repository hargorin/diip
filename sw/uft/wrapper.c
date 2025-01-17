/*
* @Author: Noah Huetter
* @Date:   2018-03-21 11:49:07
* @Last Modified by:   Noah Huetter
* @Last Modified time: 2018-03-21 15:07:11
*/
/**
 * socket wrapper functions. Source: http://unpbook.com/src.html
 */
#include "uft.h"

/**
 * @brief      Socket wrapper
 */
int Socket(int family, int type, int protocol)
{
    int     n;

    if ( (n = socket(family, type, protocol)) < 0)
    {
        err_sys("socket error");
    }
    return(n);
}

/**
 * @brief      Bind wrapper
 */
void Bind(int fd, const struct sockaddr *sa, socklen_t salen)
{
    if (bind(fd, sa, salen) < 0)
    {
        err_sys("bind error");
    }
}

/**
 * @brief      Connect wrapper
 */
void Connect(int fd, const struct sockaddr *sa, socklen_t salen)
{
    if (connect(fd, sa, salen) < 0)
        err_sys("connect error");
}

/**
 * @brief      Send wrapper
 */
void Send(int fd, const void *ptr, size_t nbytes, int flags)
{
    if (send(fd, ptr, nbytes, flags) != (ssize_t)nbytes)
        err_sys("send error");
}

/**
 * @brief      sendto wrapper
 */
void Sendto(int fd, const void *ptr, size_t nbytes, int flags,
       const struct sockaddr *sa, socklen_t salen)
{
    if (sendto(fd, ptr, nbytes, flags, sa, salen) != (ssize_t)nbytes)
    {
        err_sys("sendto error");
    }
}

/**
 * @brief      recv wrapper
 */
ssize_t Recv(int fd, void *ptr, size_t nbytes, int flags)
{
    ssize_t     n;

    if ( (n = recv(fd, ptr, nbytes, flags)) < 0)
        err_sys("recv error");
    return(n);
}

/**
 * @brief      Receive from wrapper
 */
ssize_t Recvfrom(int fd, void *ptr, size_t nbytes, int flags,
         struct sockaddr *sa, socklen_t *salenptr)
{
    ssize_t     n;

    if ( (n = recvfrom(fd, ptr, nbytes, flags, sa, salenptr)) < 0)
    {
        err_sys("recvfrom error");
    }
    return(n);
}

/**
 * @brief      Set socket options wrapper
 */
void Setsockopt(int fd, int level, int optname, const void *optval, socklen_t optlen)
{
    if (setsockopt(fd, level, optname, optval, optlen) < 0)
    {
        err_sys("setsockopt error");
    }
}