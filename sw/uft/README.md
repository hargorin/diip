
## Targets
### benchmark
Runs several benchmarks.

| number | description |
| -------- | ------------- |
|      0 | ```txBufBench``` different methods for writing into Tx buffer without loosing data |

## Notes
### Blocking vs Nonblocking
On Mac OSX the UDP socket can not be set blocking for ```ENOBUFS```. Linux default UDP socket is blocking for ```ENOBUFS``` and can be set non blocking.

### from IRC ##linux freenode
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
Total syscalls are only picked randomly from tests. No mean values.

| Commit hash | Change | Speed | filesize tested | Total syscalls |
| ----------- | ------ | ----- | --------------- | -------------- |
| 43a75ac     | Retransmission | 61.558 MB/s | 100MB | 7042 |
| 54f899b     | Sender connect() | 64.669 MB/s | 100MB | 4754 |
| 12b0196     | Receiver connect() | 63.661 MB/s | 100MB |  |
| 6117e17     | Ignore send ENOBUFS | 66.481 MB/s | 100MB |   |
|      | txbenchmark showed looping to be the best solution to the tx socket buffer problem. This version implements it to UFT | 66.481 MB/s | 100MB |   |

