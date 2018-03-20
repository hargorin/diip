

## from IRC ##linux freenode
<ayecee> noahh: poll(), test for ready to write
<ayecee> or set the fd as nonblocking and handle the EAGAIN/EWOULDBLOCK that's returned from sendto.

