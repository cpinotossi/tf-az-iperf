# az-tf-iperf
Run netperf to test latency from and to Azure VMs.

## Usefull Links:
- How to provide a Script via Terraform to an VM during setup: https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-linux#property-script
- How to use Extensions on Linux VM via Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension
- Why netperf is the right choice: https://cloud.google.com/blog/products/networking/using-netperf-and-ping-to-measure-network-latency
- netperf UI: https://flent.org/index.html
- netperf Docu: https://github.com/HewlettPackard/netperf/blob/master/doc/netperf.pdf

## Install netperf on Ubuntu
```
:~$ sudo apt-get update
:~$ sudo apt-get install netperf
```

## How to start the netserver:
```
:~$ sudo netserver -d -p 12865 -4 -v 2 -Z huhu 
```
For better debugging you can run in none Deamon mode as follow:
```
:~$ sudo netserver -D -d -p 12865 -4 -v 2 -Z huhu 
```

## How to verify if netserver is running?
```
:~$ ps -aux | grep netserver
root     23158  0.0  0.0   9788   136 ?        Ss   21:47   0:00 /usr/bin/netserver
userone 24779  0.0  0.0  12944   932 pts/0    S+   22:05   0:00 grep --color=auto netserver
```

## How to verify if port 12865 is used:
```
:~$ ss -plnt sport eq :12865
State      Recv-Q Send-Q Local Address:Port               Peer Address:Port         
     
LISTEN     0      128           :::12865                     :::*              
```

One more test with netstat instead
```
:~$ sudo netstat -tnlp | grep :12865
tcp6       0      0 :::12865                :::*                    LISTEN      2315
8/netserver 
```

## How to kill the netserver:
```
:~$ sudo killall -9 netserver
```

## How to start RTT test:
```
:~$ netperf -H 20.71.162.24,4 -v 2 -Z huhu -P 1 -t TCP_RR -- -O min_latency,mean_latency,max_latency
MIGRATED TCP REQUEST/RESPONSE TEST from 0.0.0.0 (0.0.0.0) port 0 AF_INET to 20.73.233.37 () port 0 AF_INET : demo : first burst 0
get_transport_info: getsockopt: errno 92
Minimum      Mean         Maximum
Latency      Latency      Latency
Microseconds Microseconds Microseconds

18518        32792.32     70471
```