---
layout: post
title: "如何获取客户端 IP"
description: ""
category: 
tags:
comments: yes
---

一台手机连接到 Web 服务器进行支付下单操作，Web 服务器需要获取手机的真实 IP 来做一些业务相关的策略，比如分析用户行为、限制请求频率等。用户请求经过了交换机、路由器等网络硬件设备，Nginx 等负载均衡器，Web 服务器如何获取到客户端 IP？

----

## 为什么需要 IP 和 MAC 地址？

手机发出网络请求，请求会携带 IP 和 MAC 地址。IP 已经可以定位到手机在网络中的具体位置，为什么还需有 MAC 地址？没有 MAC 地址可以完成通信吗？

先看一下 IP 报文协议，

![](https://tva1.sinaimg.cn/large/008i3skNgy1grmnoicbfjj31200eoafb.jpg)

报文中有源 IP 和目标 IP 地址，没有其他的字段来存储中转信息。

现在客户端 S 经过 A、B 路由器到达服务器 D，S 发到中转点 A 时必定要在报文中写入和 A 地址相关的信息，比如 A 的 IP 地址，这样请求到达 A 的时候 A 才知道这个请求是发给自己的。但实际上 IP 报文并没有一个中转 IP 字段。

如果可以重新设计网络协议，你可以在 IP 报文协议中加入一个中转 IP 字段，这个字段用来记录需要中转的地点。S 发往 A 时，中转 IP 填写为 A 的 IP 地址；A 发往 B 时，中转 IP 填写为 B 的 IP 地址。

而 TCP/IP 网络模型已经做了这个事情，这个中转 IP 就是 MAC，只不过它是在链路层实现的。如果协议按照中转 IP 重新设计，可以完成通信吗？如果网络只有几个节点，路由记录下转发路由表，理论上是可以通信的。但节点增多，路由就存不下了。而且在新建路由表时需要有个广播探测建表的过程，这个广播报文会发送到所有机器，会造成通信阻塞完全不可用。

怎么进行优化？分而治之？把几台机器分到一个组（局域网）里。这样路由表只用记录组里 leader 的 IP，这个 leader 就是网关。在组里通信的时候使用 MAC 来寻址，在组外就使用 IP 来寻址。MAC 寻址需要使用广播这种方式，广播更接近物理硬件实现。这个 MAC 地址能否作为中转信息放在网络层呢？为什么需要分这么多层？

----

## 为什么网络协议要分层？

分层是计算机系统中的常见操作，看看常用的互联网服务架构，从最底层到最上层依次是：

Data：数据层，包括 MySQL、Redis 等。存储用户、订单、商品数据。

DAO：Data Access Object，数据读取层，对基础数据的 CRUD。比如读取用户基本信息。

AO：逻辑组合层，对 DAO 层的数据进一步处理。比如对用户基本信息和订单信息组合，封装为一个 GetHomePage() 的接口，用于在网站首屏展示用户 home 页。

CGI：接入层，如查询用户首页，调用 GetHomePage()，展示给用户首页信息。

![](https://tva1.sinaimg.cn/large/008i3skNgy1grl2wekxkpj316m0r2199.jpg)

这样做的好处是逻辑解耦、职责分明，每一层负责特定的事务。当需要进行修改时，只需要在这一层修改而不影响其他层的服务。比如需要新增一个查询用户最近一年生活用品消费总额接口，那么在 AO 层组合查询订单 DAO 和查询商品详情 DAO 的返回数据即可。

TCP/IP 协议模型也是同样的原理。

物理层：主要是硬件电路，负责原始比特流的处理和传输。比如将模拟电\光信号转换为二进制流。代表设备是集线器。

链路层：负责 MAC 帧的处理，将源 MAC 地址、目标 MAC 地址、协议类型字段封装。代表设备是交换机。

![](https://tva1.sinaimg.cn/large/008i3skNgy1grm9nyk0xrj31gw072dhz.jpg)

网络层：负责 IP 的处理，将源 IP 地址、目标 IP 地址等字段封装。代表设备是路由器。

![](https://tva1.sinaimg.cn/large/008i3skNgy1grm9t7pbkpj31gk0h6jvf.jpg)

传输层：负责 TCP/UDP 处理，将源端口、目的端口等字段封装。

![](https://tva1.sinaimg.cn/large/008i3skNgy1grm9yq7wjwj31gq0o0dln.jpg)

应用层：负责和应用相关的协议处理，比如 HTTP、FTP。

这样分层后，应用层需要可靠的通信协议，可以使用 TCP，自己不用保证可靠性；应用层也可以基于 UDP 自己实现可靠性（比如 QUIC 协议）。如果没有分层，TCP 协议耦合在了所有层，应用层就没办法定制化了。

同时，网络层可以专心处理在组（局域网）之间的通信；链路层专心处理在组（局域网）内的通信。

----

## Nginx 代理与配置

请求经过交换机在局域网内转发，再经过路由器在局域网之间转发后到达了 Nginx。手机最开始通过域名解析获取到的服务器 IP 其实就是 Nginx。这个 TCP 的请求其实已经结束了，那么请求最终怎么到达 Web 服务器？

查看 Nginx 的配置

```
server {
    listen      80; # 监听80端口
    server_name localhost; # 配置域名

    location ^~ /gethomepage {
        proxy_pass       http://9.141.171.14:11648; // 内网 IP
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
    }
}
```

请求通过 url 匹配到规则后转给给了内网的 IP 9.141.171.14，这时 Nginx 就是新的客户端了。通过 request.getRemoteAddr 获取到的 remote_addr IP 是 TCP 底层会话 socket 连接的 IP，也就是 Nginx 的地址，显然不是客户端的 IP。获取请求到服务器的客户端 IP，可以通过读取 HTTP Header 中的字段。

+ X-Real-IP：Nginx 中可以配置，将上一级的 remote_addr 设置为 X-Real-IP
+ X-Forwarded-For：记录完整的代理链路，可以伪造

这两个字段都需要在 Nginx 中进行配置

```
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

这样请求从客户端经过交换机、路由器、Nginx 到达 Web 服务器，我们就获取到了真实的用户 IP。