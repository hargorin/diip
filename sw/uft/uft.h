

#include <stdio.h>
#include <sys/types.h> 
#include <netinet/in.h>

int uft_send_file( FILE *fp,  const char* ip, uint16_t port);
int uft_receive_file( FILE *fp,  uint16_t port);
void uft_set_verbosity(int v);