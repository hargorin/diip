

#include <stdio.h>
#include <sys/types.h> 
#include <netinet/in.h>

int udf_send_file( FILE *fp,  const char* ip, uint16_t port);
int udf_receive_file( FILE *fp,  uint16_t port);