---
layout: post
title: "KV系统实现并发锁"
description: ""
category: server
tags: []
---

在key-value系统中缓存了网络服务器上一个重要的ticket，这个ticket用来授权。在一定的时间周期7200s里更新。现需要实现一个CGI提供给前端获取这个ticket，CGI访问量为每天百万pv左右。

假设某一时刻ticket要过期时有A，B两个请求。A请求过来发现ticket过期，开始从网络服务器上获取最新的ticket并写入KV，同时服务器更新自己存储的ticket。而B恰好在A写入前读出了ticket，此时服务器上的ticket和A同步了。但B的ticket是过期的，这会导致用B获取的ticket去请求资源时失败。

因而需要读写分离。其实读写分离也意味着**并发锁转移**，从可能几K并发争锁减少到几个并发争锁。同时在CGI中降低了加锁成本。

思路如下：

* CGI只进行读KV操作
* 实现一个daemon程序，只负责每隔固定周期往KV更新ticket。用一个并发锁去控制写入时的资源竞争。

-------------------------------------

## KV实现并发锁

往KV里添加一个字段`daemon_mutex`，对应的value为`pid + timestamp`。

daemon可能会挂掉。挂掉会导致两方面问题

* daemon进程占有写锁，挂掉后死锁
* daemon进程挂掉后KV不会更新

因此可以启动三个daemon进程，相互监督。

步骤如下:

1. 3个进程争写锁，争到的进程为主进程，每隔1s刷新KV中`daemon_mutex`的timestamp字段，相当于**心跳数据**。每隔15分钟更新KV中的ticket。(ticket更新不用太频繁)
2. 2个从进程每隔1s读KV中`daemon_mutex`的timestamp字段，若`time(NULL) - kv.update_time() > 15`说明主进程挂掉了，2个从进程开始争锁，抢到的进程升级为主进程。重复以上。

分布式系统中心心跳协议的设计可以参见[Linux多线程服务端编程](http://www.amazon.cn/Linux%E5%A4%9A%E7%BA%BF%E7%A8%8B%E6%9C%8D%E5%8A%A1%E7%AB%AF%E7%BC%96%E7%A8%8B-%E4%BD%BF%E7%94%A8muduo-C-%E7%BD%91%E7%BB%9C%E5%BA%93-%E9%99%88%E7%A1%95/dp/B00FF1XYJI/ref=dp_kinw_strp_1)。

------------------------

## Chubby技术架构
如果大家熟悉 ZooKeeper(雅虎公司对Chubby的开源实现) 和 Chubby 就会发现上面的并发锁设计和 Chubby 一样。

一个典型的 Chubby 集群 通常由5台服务器组成。这些副本服务器采用 Paxos 协议，通过投票的方法来选举产生一个获得过半投票的服务器作为 Master。只有 Master 服务器才能对数据库进行写操作，而其他的服务器都是使用 Paxos 协议从 Master 服务器上同步数据库数据的更新。

在Chubby中，任意一个数据节点都可以充当一个读写锁来使用:一种是单个客户端以排他(写)模式持有这个锁，另一种则是任意数目的客户端以共享(读)模式持有这个锁。


------------------------------------------

## Memcache实现并发锁

memcache也可以利用`add`去实现并发锁，主要是通过add的原子性来判断是否要执行关键代码。

```
if (memcache.get(key) == null) {
    // 设置过期时间防止持有写锁的进程死锁
    if (memcache.add(key_mutex, 3 * 60 * 1000) == true) {
        //主进程执行流，当可以增加key_mutex字段，说明获得锁
        //业务逻辑操作
        value = db.get(key);
        memcache.set(key, value);
        //删除key_mutex
        memcache.delete(key_mutex);
    } else {
        //从进程执行流
        sleep(50);
        retry();
    }
}
```

---------------------------------------

## 参考
[http://www.cnblogs.com/dluf/p/3849075.html](http://www.cnblogs.com/dluf/p/3849075.html)

[http://timyang.net/programming/memcache-mutex/](http://timyang.net/programming/memcache-mutex/)

Linux多线程服务端编程. Page 356~360.

从Paxos到ZooKeeper——分布式一致性原理与实践
