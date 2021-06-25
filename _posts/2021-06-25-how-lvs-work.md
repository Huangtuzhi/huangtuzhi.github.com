---
layout: post
title: "LVS 工作流程"
description: ""
category: 
tags:
comments: yes
---

一个客户端请求发送到服务器，会经过域名解析获取服务器 IP，请求到达业务服务器会经过哪些网络设备？这里面的详细流程是怎么样的？

---

### 域名解析过程

域名的解析过程由本地 DNS 服务器 -> 根域名服务器 -> .com 顶级域名服务器 -> 网站权威域名服务器。

![](https://tva1.sinaimg.cn/large/008i3skNgy1grtmzryojkj30vq0i4gu5.jpg)

fuzhii.com 的权威域名服务器是 whois.dnspod.cn，腾讯云旗下品牌 DNSPod 是这个域名的服务提供商，域名解析时会逐级询问到这个服务器。

![](https://tva1.sinaimg.cn/large/008i3skNgy1grshrmzsmbj315k0n6wht.jpg)

在 DNSPod 管理平台上查看，可以看到 

![](https://tva1.sinaimg.cn/large/008i3skNgy1grshuakhd4j320a0cggo7.jpg)

> NS 记录代表域名服务器记录，如果需要把子域名交给其他 DNS 服务器解析，就需要添加 NS 记录。

DNSPod 将子域名的解析交给了 pony.dnspod.net。

NS 一般用于配置全局负载均衡 GSLB。比如腾讯的一级域名 qq.com 就配置为了 NS1.QQ.COM 用作 top GSLB NS 域名。

----

### GSLB

在域名服务商那里配置好 GSLB NS 后所有的域名解析都会交给 GSLB 来处理。GSLB 主要功能是可根据访问者的位置，提供就近接入能力，减少请求耗时。GSLB 相当于公司/个人定制的 DNS 域名解析器。

在 GSLB 上给域名（app.com.cn）绑定服务器对应的公网 IP。这些映射表由运维负责维护和配置。

```
app.com.cn 14.215.140.116
app.com.cn 183.3.235.18
```

这些 IP 是内部服务器的真实 IP 吗？内部服务器由于安全原因不会配置外网策略，只有内网 IP。那如何让外网用户访问到部署在内网的服务？

----

### LVS

查看 Nginx 上的网络配置

```
Nginx1=14.215.140.116;183.3.235.18;

Nginx2=14.215.140.116;183.3.235.18;
```

多台 Nginx 上都配置了相同的 IP，这是怎么做到的？IP 不会冲突吗？这样做的好处是什么？

DNS 过程：客户端 -> GSLB -> 返回 app.com.cn 域名配置的一个 IP 14.215.140.116 

TCP 连接过程：client -> LVS LD(Load banlance Director)-> RS(Real Server，这里对应 Nginx)

LVS LD 和 RS 网卡上配置的都是 14.215.140.116，LD 会通过 IP 隧道技术将请求从 LD 转发到 RS。

----

### IP 隧道技术

使用 ifconfig 可以看到这个 Nginx 模块有 14.215.140.116 等公网 IP，这个公网 IP 其实是由 LVS 在这个机器上配置的虚拟 IP（VIP)。

```
tunl0:0: flags=193<UP,RUNNING,NOARP>  mtu 1480
        inet 14.215.140.116  netmask 255.255.255.255
        tunnel   txqueuelen 0  (IPIP Tunnel)

tunl0:8: flags=193<UP,RUNNING,NOARP>  mtu 1480
        inet 183.3.235.18  netmask 255.255.255.255
        tunnel   txqueuelen 0  (IPIP Tunnel)
```

LVS 使用内核模块虚拟出了一些网卡，再在这些网卡上绑定公网 IP。

整个转发流程如图所示：

![](https://tva1.sinaimg.cn/large/008i3skNgy1gruldxw04sj31fc0iswra.jpg)

这样用户就访问到了内网的服务，LVS 可以将用户请求通过策略任意转发到对等的 Nginx1 或 Nginx2 上，这样就实现了网络层的负载均衡。

---

### 参考

[Linux 中 IP 隧道](https://sites.google.com/site/emmoblin/linux-network-1/linux-zhongip-sui-dao)


[Nginx 四层七层代理区别](https://blog.csdn.net/weixin_44685869/article/details/105572608)

[LVS 负载均衡原理](https://www.cnblogs.com/zhangxingeng/p/10497279.html)
