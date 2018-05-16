
#ifndef WRAPPER_H
#define WRAPPER_H

int Socket(int family, int type, int protocol);
void Bind(int fd, const struct sockaddr *sa, socklen_t salen);
void Connect(int fd, const struct sockaddr *sa, socklen_t salen);

void Send(int fd, const void *ptr, size_t nbytes, int flags);
void Sendto(int fd, const void *ptr, size_t nbytes, int flags,
       const struct sockaddr *sa, socklen_t salen);

ssize_t Recv(int fd, void *ptr, size_t nbytes, int flags);
ssize_t Recvfrom(int fd, void *ptr, size_t nbytes, int flags,
         struct sockaddr *sa, socklen_t *salenptr);

void Setsockopt(int fd, int level, int optname, 
    const void *optval, socklen_t optlen);

#endif