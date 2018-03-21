

## from IRC ##linux freenode
<ayecee> noahh: poll(), test for ready to write
<ayecee> or set the fd as nonblocking and handle the EAGAIN/EWOULDBLOCK that's returned from sendto.

## Benchmark using iperf3
### Receiver
```bash
iperf3 --server
```
### Sender
```bash
iperf3 --client 192.168.5.32 --bandwidth 1G  --length 1500 --udp --port 5201 --parallel 1
```

## Benchmark UFT
Local network with destination client on ```192.168.5.32``` run:
```bash
./remotebench.sh
```

To measure throughput on client run
```bash
sudo tcpdump -i enp5s0 -l -e -n 'udp port 2222' | ./netbps
```

## Progress

| Commit hash | Change | Speed | filesize tested |
| ----------- | ------ | ----- | --------------- |
| 43a75ac     | Retransmission | 61.558 MB/s | 100MB | 