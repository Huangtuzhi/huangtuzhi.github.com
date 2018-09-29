---
layout: post
title: "使用 tcpdump 抓包"
description: ""
category: 
tags:
comments: yes
---

最近在使用专线与商户联调接口时，遇到了一个问题：可以 telnet 联通，但无法调通服务接口。总结下使用 tcpdump 抓包分析的过程。

----

## 查看三次握手过程

使用命令 `sudo tcpdump host 131.87.110.XX -i eth0` 查看握手过程。

-i：指定监听的网卡，有的机器有多块网卡。我测试的机器 eth0 能抓到收发的包，而 eth1 只能抓到收的包。

host：指定要监听的包的来源 IP。131.87.110.XX 为对端的商户 IP，报文中使用 remote_mch_IP 代替。

一个正常的握手过程如下：

```
local_IP > remote_mch_IP: Flags [S], seq 3477165558, win 14600, options [mss 1460,
           sackOK,TS val 2745901398 ecr 0,nop,wscale 7], length 0
remote_mch_IP > local_IP: Flags [S.], seq 4207730004, ack 3477165559, win 4344, options 
           [mss 1448,nop,wscale 0,nop,nop,TS val 615225318 ecr 2745901398,sackOK,eol], length 0
local_IP > remote_mch_IP: Flags [.], ack 1, win 115, length 0
local_IP > remote_mch_IP: Flags [P.], seq 1:217, ack 1, win 115, length 216
remote_mch_IP > local_IP: Flags [.], ack 217, win 4560, options 
           [nop,nop,TS val 615225423 ecr 0], length 0
local_IP > remote_mch_IP: Flags [P.], seq 217:617, ack 1, win 115, length 400
17:31:57.351655 IP remote_mch_IP > local_IP: Flags [P.], seq 1:900, ack 617, 
           win 4960, options [nop,nop,TS val 615225514 ecr 0], length 899
local_IP > remote_mch_IP: Flags [.], ack 900, win 129, length 0
remote_mch_IP > local_IP: Flags [P.], seq 900:905, ack 617, win 4960, 
           options [nop,nop,TS val 615225514 ecr 0], length 5
local_IP > remote_mch_IP: Flags [.], ack 905, win 129, length 0
local_IP > remote_mch_IP: Flags [F.], seq 617, ack 905, win 129, length 0
remote_mch_IP > local_IP: Flags [.], ack 618, win 4960, options [nop,nop,TS 
           val 615225519 ecr 0], length 0
remote_mch_IP > local_IP: Flags [F.], seq 905, ack 618, win 4960, 
           options [nop,nop,TS val 615225520 ecr 0], length 0
local_IP > remote_mch_IP: Flags [.], ack 906, win 129, length 0
```

实际的返回是：

```
remote_mch_IP > local_IP: Flags [S.], seq 292384097, ack 3465124193, win 4344, options [
           mss 1448,nop,wscale 0,nop,nop,TS val 1517140641 ecr 1897638408,sackOK,eol], length 0
remote_mch_IP > local_IP: Flags [R.], seq 1, ack 558, win 0, length 0
```

### 回包标志

```
S=SYN          发起连接标志
P=PUSH         传送数据标志
F=FIN          关闭连接标志
ack            表示确认包
RST=RESET      异常关闭连接
[.]            表示没有任何标志
```

可以看到对端服务器发送一个 SYN 后直接 RESET 了。

-----

## 原因分析

服务器端因为某种原因关闭了连接（如服务 Coredump，调用 Socket.close() 方法等），而客户端依然在读写数据，此时服务器会返回复位标志 RST。

-----

## 参考

[TCP 出现 RST 的几种情况](https://www.cnblogs.com/JohnABC/p/6323046.html)

[TCP 中的 RST 标志详解](https://blog.csdn.net/erlib/article/details/50132307)

[TCP 滑动窗口演示](https://v.youku.com/v_show/id_XNDg1NDUyMDUy.html)

[TCP 的那些事（上）](https://coolshell.cn/articles/11564.html)

[TCP 的那些事（下）](https://coolshell.cn/articles/11609.html)
